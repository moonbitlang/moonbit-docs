"""Resolve exact MoonBit definition locations to public Mooncakes docs.

This module is deliberately independent from the semantic snapshot and Sphinx
layers.  It accepts an already-resolved package identity and a one-based source
location, then requires three matching pieces of Mooncakes data before it
returns a link:

* the package manifest;
* the module-wide public symbol index;
* the package data containing the exact definition location.

Anything that cannot be proved by those inputs is reported as unresolved.  In
particular, implementation methods, fields, constructors, and approximate
source locations never acquire guessed links.
"""

from __future__ import annotations

from concurrent.futures import Future
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import tempfile
import threading
from typing import Any, Callable, Mapping
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

from .canonical import canonical_json_bytes


PROVIDER = "mooncakes"
DEFAULT_BASE_URL = "https://mooncakes.io"
CACHE_SCHEMA = "moonbit-semantic-mooncakes-cache/v1"
MAX_RESPONSE_BYTES = 32 * 1024 * 1024

Fetcher = Callable[[str], Any]


@dataclass(frozen=True)
class DefinitionEvidence:
    """A package-qualified, one-based definition location from Moon LSP."""

    module: str
    requested_version: str
    package: str
    file: str
    line: int
    column: int


@dataclass(frozen=True)
class MooncakesResolution:
    """The result of proving a definition against Mooncakes public data."""

    status: str
    module: str
    requested_version: str
    package: str
    file: str
    line: int
    column: int
    resolved_version: str = ""
    symbol_kind: str = ""
    fragment: str = ""
    url: str = ""
    manifest_url: str = ""
    module_index_url: str = ""
    package_data_url: str = ""
    provider: str = PROVIDER
    reason: str = ""

    @property
    def exact(self) -> bool:
        return self.status == "exact"


@dataclass(frozen=True)
class _Route:
    fragment: str
    symbol_kind: str


@dataclass(frozen=True)
class _LocatedRoute:
    route: _Route
    path: str
    file: str
    line: int
    column: int


class _OfflineCacheMiss(RuntimeError):
    def __init__(self, url: str):
        super().__init__(f"Mooncakes cache has no entry for {url}")
        self.url = url


class _ProviderDataError(ValueError):
    pass


class MooncakesClient:
    """A cached, single-flight Mooncakes JSON client and exact resolver.

    ``fetcher`` is injectable so tests and callers can supply an HTTP policy.
    It receives one URL and may return a JSON-compatible value, UTF-8 text, or
    bytes.  The default implementation performs a bounded HTTPS GET.
    """

    def __init__(
        self,
        cache_dir: str | Path,
        *,
        offline: bool = False,
        refresh: bool = False,
        fetcher: Fetcher | None = None,
        base_url: str = DEFAULT_BASE_URL,
    ) -> None:
        self.cache_dir = Path(cache_dir).expanduser().resolve()
        self.offline = bool(offline)
        self.refresh = bool(refresh)
        self.fetcher = fetcher or self._default_fetcher
        self.base_url = base_url.rstrip("/")
        parsed = urlparse(self.base_url)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError(f"invalid Mooncakes base URL: {base_url!r}")
        self._flight_lock = threading.Lock()
        self._inflight: dict[str, Future[Mapping[str, Any]]] = {}

    def resolve(self, evidence: DefinitionEvidence) -> MooncakesResolution:
        """Return an exact public route or a non-linking status."""

        invalid = _validate_evidence(evidence)
        manifest_url = self._manifest_url(evidence) if invalid is None else ""
        result_fields = {
            "module": evidence.module,
            "requested_version": evidence.requested_version,
            "package": evidence.package,
            "file": evidence.file,
            "line": evidence.line,
            "column": evidence.column,
            "manifest_url": manifest_url,
        }
        if invalid is not None:
            return MooncakesResolution(
                status="invalid-evidence", reason=invalid, **result_fields
            )

        try:
            manifest = self._json_for(manifest_url)
            manifest_problem = _validate_manifest(manifest, evidence)
            resolved_version = str(manifest.get("version") or "")
            if manifest_problem is not None:
                return MooncakesResolution(
                    status="unavailable",
                    resolved_version=resolved_version,
                    reason=manifest_problem,
                    **result_fields,
                )

            module_index_url = self._module_index_url(
                evidence.module, resolved_version
            )
            package_data_url = self._package_data_url(
                evidence.module,
                resolved_version,
                evidence.package,
            )
            endpoint_fields = {
                **result_fields,
                "resolved_version": resolved_version,
                "module_index_url": module_index_url,
                "package_data_url": package_data_url,
            }
            module_index = self._json_for(module_index_url)
            package_data = self._json_for(package_data_url)
            package_indices = _package_indices(module_index, evidence.package)
            if len(package_indices) != 1:
                status = "ambiguous" if package_indices else "unsupported"
                return MooncakesResolution(
                    status=status,
                    reason=(
                        "Mooncakes module index contains multiple matching packages"
                        if package_indices
                        else "Mooncakes module index has no matching package"
                    ),
                    **endpoint_fields,
                )
            if package_data.get("name") != evidence.package:
                return MooncakesResolution(
                    status="unavailable",
                    reason="Mooncakes package data identity does not match the request",
                    **endpoint_fields,
                )

            public_routes = _public_routes(package_indices[0])
            located_routes = _located_routes(package_data)
            matches = [
                item
                for item in located_routes
                if item.route in public_routes and _location_matches(item, evidence)
            ]
            if not matches:
                return MooncakesResolution(
                    status="unsupported",
                    reason="no exact supported Mooncakes symbol at the definition location",
                    **endpoint_fields,
                )
            if len(matches) != 1:
                return MooncakesResolution(
                    status="ambiguous",
                    reason="multiple Mooncakes symbols share the definition location",
                    **endpoint_fields,
                )

            match = matches[0]
            url = self._docs_url(
                evidence.module,
                resolved_version,
                evidence.package,
                match.route.fragment,
            )
            return MooncakesResolution(
                status="exact",
                symbol_kind=match.route.symbol_kind,
                fragment=match.route.fragment,
                url=url,
                **endpoint_fields,
            )
        except _OfflineCacheMiss as exc:
            return MooncakesResolution(
                status="offline-miss", reason=str(exc), **result_fields
            )
        except (OSError, UnicodeError, ValueError, TypeError) as exc:
            return MooncakesResolution(
                status="provider-error", reason=str(exc), **result_fields
            )

    def cache_path(self, url: str) -> Path:
        """Return the deterministic URL-keyed cache path."""

        digest = hashlib.sha256(url.encode("utf-8")).hexdigest()
        return self.cache_dir / f"{digest}.json"

    def _json_for(self, url: str) -> Mapping[str, Any]:
        with self._flight_lock:
            future = self._inflight.get(url)
            if future is None:
                future = Future()
                self._inflight[url] = future
                leader = True
            else:
                leader = False
        if not leader:
            return future.result()

        try:
            value = self._load_json(url)
        except BaseException as exc:
            future.set_exception(exc)
            raise
        else:
            future.set_result(value)
            return value

    def _load_json(self, url: str) -> Mapping[str, Any]:
        path = self.cache_path(url)
        if path.is_file() and (self.offline or not self.refresh):
            try:
                return _read_cache(path, url)
            except (OSError, UnicodeError, json.JSONDecodeError, _ProviderDataError):
                if self.offline:
                    raise
        if self.offline:
            raise _OfflineCacheMiss(url)

        try:
            fetched = self.fetcher(url)
        except (OSError, UnicodeError, ValueError, TypeError):
            raise
        except Exception as exc:
            raise OSError(f"Mooncakes request failed for {url}: {exc}") from exc
        payload = _coerce_payload(fetched, url)
        _atomic_write_cache(path, url, payload)
        return payload

    def _manifest_url(self, evidence: DefinitionEvidence) -> str:
        suffix = _package_suffix(evidence.module, evidence.package)
        module = _quote_path(evidence.module)
        if evidence.module != "moonbitlang/core":
            module += "@" + quote(evidence.requested_version, safe="._~+-")
        path = module + ("/" + _quote_path(suffix) if suffix else "")
        return f"{self.base_url}/api/v0/manifest/{path}"

    def _module_index_url(self, module: str, version: str) -> str:
        asset = _quote_path(module) + "@" + quote(version, safe="._~+-")
        return f"{self.base_url}/assets/{asset}/module_index.json"

    def _package_data_url(
        self, module: str, version: str, package: str
    ) -> str:
        suffix = _package_suffix(module, package)
        asset = _quote_path(module) + "@" + quote(version, safe="._~+-")
        path = asset + ("/" + _quote_path(suffix) if suffix else "")
        return f"{self.base_url}/assets/{path}/package_data.json"

    def _docs_url(
        self,
        module: str,
        version: str,
        package: str,
        fragment: str,
    ) -> str:
        suffix = _package_suffix(module, package)
        path = _quote_path(module)
        if module != "moonbitlang/core":
            path += "@" + quote(version, safe="._~+-")
        if suffix:
            path += "/" + _quote_path(suffix)
        # Mooncakes' DOM IDs use a literal ``Type::method`` spelling.  Keep the
        # two colons readable instead of turning them into ``%3A%3A``.
        encoded_fragment = quote(fragment, safe=":._~-")
        return f"{self.base_url}/docs/{path}#{encoded_fragment}"

    @staticmethod
    def _default_fetcher(url: str) -> bytes:
        request = Request(
            url,
            headers={
                "Accept": "application/json",
                "User-Agent": "moonbit-docs-semantic-indexer/1",
            },
        )
        with urlopen(request, timeout=20) as response:
            data = response.read(MAX_RESPONSE_BYTES + 1)
        if len(data) > MAX_RESPONSE_BYTES:
            raise OSError(f"Mooncakes response exceeds {MAX_RESPONSE_BYTES} bytes")
        return data


def _validate_evidence(evidence: DefinitionEvidence) -> str | None:
    for label, value in (
        ("module", evidence.module),
        ("package", evidence.package),
        ("file", evidence.file),
    ):
        if not isinstance(value, str) or not value:
            return f"{label} must be a non-empty string"
    if evidence.module != "moonbitlang/core" and not evidence.requested_version:
        return "non-core definitions require an exact requested version"
    try:
        module = _clean_path(evidence.module)
        package = _clean_path(evidence.package)
        _clean_path(evidence.file)
    except ValueError as exc:
        return str(exc)
    if package != module and not package.startswith(module + "/"):
        return "package is outside the requested module"
    if type(evidence.line) is not int or evidence.line < 1:
        return "line must be a positive one-based integer"
    if type(evidence.column) is not int or evidence.column < 1:
        return "column must be a positive one-based integer"
    return None


def _validate_manifest(
    manifest: Mapping[str, Any], evidence: DefinitionEvidence
) -> str | None:
    expected = {
        "name": evidence.package,
        "module": evidence.module,
    }
    for field, value in expected.items():
        if manifest.get(field) != value:
            return f"Mooncakes manifest {field} does not match {value!r}"
    version = manifest.get("version")
    if not isinstance(version, str) or not version:
        return "Mooncakes manifest has no resolved version"
    if (
        evidence.module != "moonbitlang/core"
        and version != evidence.requested_version
    ):
        return "Mooncakes manifest did not resolve the requested version"
    if manifest.get("has_package") is not True:
        return "Mooncakes manifest reports no package documentation"
    if manifest.get("build_status") != "success":
        return "Mooncakes documentation build is not successful"
    return None


def _package_indices(
    module_index: Mapping[str, Any], package: str
) -> list[Mapping[str, Any]]:
    result: list[Mapping[str, Any]] = []

    def visit(node: Any) -> None:
        if not isinstance(node, Mapping):
            raise _ProviderDataError("Mooncakes module index node must be an object")
        value = node.get("package")
        if isinstance(value, Mapping) and value.get("path") == package:
            result.append(value)
        children = node.get("childs", [])
        if not isinstance(children, list):
            raise _ProviderDataError("Mooncakes module index childs must be an array")
        for child in children:
            visit(child)

    visit(module_index)
    return result


def _public_routes(package_index: Mapping[str, Any]) -> set[_Route]:
    result: set[_Route] = set()
    for field, kind in (
        ("typealias", "typealias"),
        ("values", "value"),
    ):
        for value in _array(package_index, field):
            if isinstance(value, str) and value:
                result.add(_Route(value, kind))
            else:
                raise _ProviderDataError(
                    f"Mooncakes module index {field} entries must be strings"
                )
    for field, kind, methods in (
        ("traits", "trait", False),
        ("errors", "error", True),
        ("types", "type", True),
        ("misc", "misc", True),
    ):
        for value in _array(package_index, field):
            if not isinstance(value, Mapping) or not isinstance(
                value.get("name"), str
            ):
                raise _ProviderDataError(
                    f"Mooncakes module index {field} entries must be named objects"
                )
            owner = value["name"]
            result.add(_Route(owner, kind))
            if methods:
                for method in _array(value, "methods"):
                    if not isinstance(method, str) or not method:
                        raise _ProviderDataError(
                            "Mooncakes module index methods must be strings"
                        )
                    result.add(_Route(f"{owner}::{method}", "method"))
    return result


def _located_routes(package_data: Mapping[str, Any]) -> list[_LocatedRoute]:
    result: list[_LocatedRoute] = []
    for field, kind, methods in (
        ("typealias", "typealias", False),
        ("traits", "trait", False),
        ("errors", "error", True),
        ("types", "type", True),
        ("values", "value", False),
        ("misc", "misc", True),
    ):
        for value in _array(package_data, field):
            if not isinstance(value, Mapping) or not isinstance(
                value.get("name"), str
            ):
                raise _ProviderDataError(
                    f"Mooncakes package data {field} entries must be named objects"
                )
            owner = value["name"]
            located = _located(_Route(owner, kind), value.get("loc"))
            if located is not None:
                result.append(located)
            if methods:
                for method in _array(value, "methods"):
                    if not isinstance(method, Mapping) or not isinstance(
                        method.get("name"), str
                    ):
                        raise _ProviderDataError(
                            "Mooncakes package data methods must be named objects"
                        )
                    located = _located(
                        _Route(f"{owner}::{method['name']}", "method"),
                        method.get("loc"),
                    )
                    if located is not None:
                        result.append(located)
            # Deliberately do not traverse ``impls``.  Mooncakes does not expose
            # their methods with the stable ``Type::method`` contract.
    return result


def _located(route: _Route, value: Any) -> _LocatedRoute | None:
    # Current ``misc`` records may have no location.  They remain valid public
    # routes, but cannot be selected by exact Definition evidence.
    if value is None:
        return None
    if not isinstance(value, Mapping):
        raise _ProviderDataError("Mooncakes symbol loc must be an object")
    path = value.get("path")
    file = value.get("file")
    line = value.get("line")
    column = value.get("column")
    if not isinstance(path, str) or not isinstance(file, str):
        raise _ProviderDataError("Mooncakes symbol loc requires path and file")
    if not isinstance(line, int) or not isinstance(column, int):
        raise _ProviderDataError("Mooncakes symbol loc requires integer coordinates")
    return _LocatedRoute(route, path, file, line, column)


def _location_matches(
    item: _LocatedRoute, evidence: DefinitionEvidence
) -> bool:
    return (
        _clean_path(item.path) == _clean_path(evidence.package)
        and _clean_path(item.file) == _clean_path(evidence.file)
        and item.line == evidence.line
        and item.column == evidence.column
    )


def _array(value: Mapping[str, Any], field: str) -> list[Any]:
    result = value.get(field, [])
    if not isinstance(result, list):
        raise _ProviderDataError(f"Mooncakes {field} must be an array")
    return result


def _package_suffix(module: str, package: str) -> str:
    if package == module:
        return ""
    return package[len(module) + 1 :]


def _clean_path(value: str) -> str:
    path = PurePosixPath(value.replace("\\", "/"))
    if path.is_absolute() or not path.parts or any(
        part in {"", ".", ".."} for part in path.parts
    ):
        raise ValueError(f"unsafe Mooncakes path: {value!r}")
    return "/".join(path.parts)


def _quote_path(value: str) -> str:
    if not value:
        return ""
    return "/".join(quote(part, safe="._~-+") for part in _clean_path(value).split("/"))


def _coerce_payload(value: Any, url: str) -> Mapping[str, Any]:
    if isinstance(value, bytes):
        if len(value) > MAX_RESPONSE_BYTES:
            raise OSError(f"Mooncakes response exceeds {MAX_RESPONSE_BYTES} bytes")
        value = json.loads(value.decode("utf-8"))
    elif isinstance(value, str):
        if len(value.encode("utf-8")) > MAX_RESPONSE_BYTES:
            raise OSError(f"Mooncakes response exceeds {MAX_RESPONSE_BYTES} bytes")
        value = json.loads(value)
    if not isinstance(value, Mapping):
        raise _ProviderDataError(f"Mooncakes JSON response is not an object: {url}")
    # Round-trip through canonical JSON so callers cannot mutate a shared fake
    # response while another resolution is using it.
    return json.loads(canonical_json_bytes(dict(value)))


def _read_cache(path: Path, url: str) -> Mapping[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, Mapping):
        raise _ProviderDataError(f"invalid Mooncakes cache entry: {path}")
    if value.get("schema") != CACHE_SCHEMA or value.get("url") != url:
        raise _ProviderDataError(f"Mooncakes cache identity mismatch: {path}")
    payload = value.get("payload")
    if not isinstance(payload, Mapping):
        raise _ProviderDataError(f"Mooncakes cache payload is not an object: {path}")
    payload_digest = value.get("payload_digest")
    actual_digest = "sha256:" + hashlib.sha256(
        canonical_json_bytes(dict(payload))
    ).hexdigest()
    if payload_digest != actual_digest:
        raise _ProviderDataError(f"Mooncakes cache payload digest mismatch: {path}")
    return dict(payload)


def _atomic_write_cache(
    path: Path, url: str, payload: Mapping[str, Any]
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload_digest = "sha256:" + hashlib.sha256(
        canonical_json_bytes(dict(payload))
    ).hexdigest()
    content = canonical_json_bytes(
        {
            "schema": CACHE_SCHEMA,
            "url": url,
            "payload": dict(payload),
            "payload_digest": payload_digest,
        }
    )
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)
