"""Read and validate the portable MoonBit semantic snapshot format.

The renderer deliberately knows nothing about Moon installations or checkout
paths.  Every byte it publishes comes from a content-addressed snapshot blob.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Mapping
from urllib.parse import quote, urlsplit


SCHEMA_VERSION = 1
ACCEPTED_SCHEMAS = {
    1,
    "1",
    "moonbit-semantic-v1",
    "moonbit-semantic/1",
    "moonbit-semantic-snapshot/v1",
}
EXTERNAL_TARGET_TABLE = "external-targets.jsonl"


class SnapshotError(ValueError):
    """The snapshot is absent, corrupt, unsafe, or incompatible."""


def _digest_name(value: str) -> str:
    return value.removeprefix("sha256:")


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _safe_relative(value: str, *, label: str) -> PurePosixPath:
    path = PurePosixPath(value.replace("\\", "/"))
    if path.is_absolute() or ".." in path.parts:
        raise SnapshotError(f"unsafe {label}: {value!r}")
    return path


def _range(value: Any, *, label: str) -> tuple[int, int]:
    if isinstance(value, Mapping):
        value = value.get("utf8") or value.get("byte_range") or value.get("range")
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        raise SnapshotError(f"{label} must be a two-element UTF-8 byte range")
    start, end = value
    if not isinstance(start, int) or not isinstance(end, int) or start < 0 or end < start:
        raise SnapshotError(f"invalid {label}: {value!r}")
    return start, end


def _json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SnapshotError(f"cannot read JSON {path}: {exc}") from exc


def _jsonl(path: Path, *, required: bool = False) -> list[dict[str, Any]]:
    if not path.exists():
        if required:
            raise SnapshotError(f"required snapshot shard is missing: {path.name}")
        return []
    records: list[dict[str, Any]] = []
    try:
        for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not raw.strip():
                continue
            value = json.loads(raw)
            if not isinstance(value, dict):
                raise SnapshotError(f"{path}:{number}: JSONL record must be an object")
            records.append(value)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SnapshotError(f"cannot read JSONL {path}: {exc}") from exc
    return records


@dataclass(frozen=True)
class DefinitionTarget:
    source_id: str
    selection_range: tuple[int, int]
    symbol_id: str | None = None
    target_range: tuple[int, int] | None = None
    external_target_id: str | None = None
    external_status: str | None = None


@dataclass(frozen=True)
class ExternalTarget:
    external_target_id: str
    provider: str
    module: str
    resolved_version: str
    package: str
    anchor: str
    url: str
    status: str = "exact"
    requested_version: str = ""
    match: str = ""
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class Occurrence:
    source_id: str
    byte_range: tuple[int, int]
    context_id: str | None = None
    symbol_id: str | None = None
    hover_id: str | None = None
    role: str = "reference"
    definitions: tuple[DefinitionTarget, ...] = ()
    preferred_external_target_id: str | None = None


@dataclass(frozen=True)
class Symbol:
    symbol_id: str
    source_id: str
    byte_range: tuple[int, int]
    name: str
    kind: str = "object"
    package: str = ""
    module: str = ""
    hover_id: str | None = None
    qualified_name: str | None = None


@dataclass(frozen=True)
class Source:
    source_id: str
    path: str
    blob_digest: str
    kind: str
    origin: str = "local"
    module: str = ""
    version: str = ""
    package: str = ""
    context_id: str | None = None
    analysis_status: str = "complete"
    route_key: str | None = None
    title: str | None = None
    metadata: Mapping[str, Any] = field(default_factory=dict)

    @property
    def literate(self) -> bool:
        return self.kind in {"mbt.md", ".mbt.md", "literate", "moonbit-markdown"} or self.path.endswith(".mbt.md")


@dataclass(frozen=True)
class Asset:
    asset_id: str
    owner_source_id: str
    path: str
    blob_digest: str
    mime: str = "application/octet-stream"


@dataclass
class SemanticSnapshot:
    root: Path
    manifest: Mapping[str, Any]
    sources: dict[str, Source]
    assets: dict[str, Asset]
    symbols: dict[str, Symbol]
    occurrences: dict[str, tuple[Occurrence, ...]]
    hovers: dict[str, Any]
    corpus_digest: str
    external_targets: dict[str, ExternalTarget] = field(default_factory=dict)
    _blob_cache: dict[str, bytes] = field(default_factory=dict, repr=False)

    def blob_bytes(self, source: Source) -> bytes:
        digest = _digest_name(source.blob_digest)
        cached = self._blob_cache.get(digest)
        if cached is not None:
            return cached
        candidates = (self.root / "blobs" / "sha256" / digest, self.root / "blobs" / digest)
        blob = next((path for path in candidates if path.is_file()), None)
        if blob is None:
            raise SnapshotError(f"source {source.source_id!r} has no blob {digest}")
        data = blob.read_bytes()
        if _sha256(data) != digest:
            raise SnapshotError(f"blob digest mismatch for {source.source_id!r}")
        self._blob_cache[digest] = data
        return data

    def source_text(self, source: Source) -> str:
        try:
            return self.blob_bytes(source).decode("utf-8")
        except UnicodeDecodeError as exc:
            raise SnapshotError(f"source {source.source_id!r} is not UTF-8") from exc

    def asset_bytes(self, asset: Asset) -> bytes:
        digest = _digest_name(asset.blob_digest)
        cached = self._blob_cache.get(digest)
        if cached is not None:
            return cached
        path = self.root / "blobs" / "sha256" / digest
        if not path.is_file():
            raise SnapshotError(f"asset {asset.asset_id!r} has no blob {digest}")
        data = path.read_bytes()
        if _sha256(data) != digest:
            raise SnapshotError(f"asset blob digest mismatch for {asset.asset_id!r}")
        self._blob_cache[digest] = data
        return data

    def validate(self) -> None:
        for source in self.sources.values():
            data = self.blob_bytes(source)
            size = len(data)
            for occurrence in self.occurrences.get(source.source_id, ()):
                if occurrence.byte_range[1] > size:
                    raise SnapshotError(f"occurrence outside {source.source_id!r} blob")
                for target in occurrence.definitions:
                    if target.source_id not in self.sources:
                        raise SnapshotError(f"definition targets unknown source {target.source_id!r}")
                    _validate_definition_external_target(
                        target,
                        self.sources[target.source_id],
                        self.external_targets,
                    )
                if occurrence.preferred_external_target_id is not None:
                    if not occurrence.definitions or any(
                        target.external_status is None
                        or self.sources[target.source_id].origin
                        in {"local", "standalone"}
                        for target in occurrence.definitions
                    ):
                        raise SnapshotError(
                            "occurrence preferred external target is mixed with "
                            "a local definition"
                        )
                    if not any(
                        target.external_status == "exact"
                        and target.external_target_id
                        == occurrence.preferred_external_target_id
                        for target in occurrence.definitions
                    ):
                        raise SnapshotError(
                            "occurrence preferred external target is not an "
                            "exact definition"
                        )
            # A path is presentation metadata, but must still be portable.
            _safe_relative(source.path, label="source path")
        for symbol in self.symbols.values():
            source = self.sources.get(symbol.source_id)
            if source is None:
                raise SnapshotError(f"symbol {symbol.symbol_id!r} targets unknown source")
            if symbol.byte_range[1] > len(self.blob_bytes(source)):
                raise SnapshotError(f"symbol {symbol.symbol_id!r} is outside its blob")
        for asset in self.assets.values():
            if asset.owner_source_id not in self.sources:
                raise SnapshotError(f"asset {asset.asset_id!r} has unknown owner")
            _safe_relative(asset.path, label="asset path")
            self.asset_bytes(asset)
        for target_id, target in self.external_targets.items():
            if target_id != target.external_target_id:
                raise SnapshotError("external target map key does not match its record ID")
            _validate_external_target_value(target)


def _source(record: Mapping[str, Any]) -> Source:
    source_id = record.get("source_id") or record.get("id")
    digest = record.get("blob_digest") or record.get("digest") or record.get("blob")
    path = record.get("path") or record.get("logical_path")
    if not all(isinstance(item, str) and item for item in (source_id, digest, path)):
        raise SnapshotError("source records require source_id, path, and blob_digest")
    return Source(
        source_id=source_id,
        path=path,
        blob_digest=digest,
        kind=str(record.get("kind") or record.get("source_kind") or PurePosixPath(path).suffix),
        origin=str(record.get("origin") or source_id.partition(":")[0] or "local"),
        module=str(record.get("module") or ""),
        version=str(record.get("version") or record.get("revision") or ""),
        package=str(record.get("package") or ""),
        context_id=record.get("context_id") or record.get("canonical_context_id"),
        analysis_status=str(record.get("analysis_status") or "complete"),
        route_key=record.get("route_key") or record.get("source_page_route_key"),
        title=record.get("title"),
        metadata=dict(record),
    )


def _symbol(record: Mapping[str, Any]) -> Symbol:
    symbol_id = record.get("symbol_id") or record.get("id")
    source_id = record.get("source_id") or record.get("definition_source_id")
    selected = record.get("selection_range_utf8") or record.get("definition_range_utf8") or record.get("byte_range")
    if not isinstance(symbol_id, str) or not isinstance(source_id, str):
        raise SnapshotError("symbol records require symbol_id and source_id")
    return Symbol(
        symbol_id=symbol_id,
        source_id=source_id,
        byte_range=_range(selected, label=f"symbol {symbol_id} range"),
        name=str(record.get("name") or record.get("qualified_name") or symbol_id),
        kind=str(record.get("kind") or "object"),
        package=str(record.get("package") or ""),
        module=str(record.get("module") or ""),
        hover_id=record.get("hover_id"),
        qualified_name=record.get("qualified_name") or record.get("logical_symbol_key"),
    )


def _asset(record: Mapping[str, Any]) -> Asset:
    required = (record.get("asset_id"), record.get("owner_source_id"), record.get("path"), record.get("blob_digest"))
    if not all(isinstance(item, str) and item for item in required):
        raise SnapshotError("asset records require asset_id, owner_source_id, path, and blob_digest")
    return Asset(required[0], required[1], required[2], required[3], str(record.get("mime") or "application/octet-stream"))


def _segments(value: Any, *, field: str) -> list[str]:
    if not isinstance(value, str) or not value or value.startswith("/") or value.endswith("/"):
        raise SnapshotError(f"external target {field} must be a non-empty slash-separated string")
    parts = value.split("/")
    if any(not part or part in {".", ".."} for part in parts):
        raise SnapshotError(f"external target has invalid {field}: {value!r}")
    return parts


def _encoded_segment(value: str) -> str:
    # ``@`` is Mooncakes' version separator in the final module segment.
    return quote(value, safe="-._~+@")


def _external_target_url(target: ExternalTarget) -> str:
    if target.provider != "mooncakes" or target.status != "exact":
        raise SnapshotError("external target records must be exact Mooncakes routes")
    module_parts = _segments(target.module, field="module")
    package_parts = _segments(target.package, field="package")
    if not target.resolved_version:
        raise SnapshotError("external target resolved_version must be non-empty")
    if not target.anchor:
        raise SnapshotError("external target anchor must be non-empty")
    if package_parts[: len(module_parts)] != module_parts:
        raise SnapshotError("external target package must belong to its module")
    if target.module == "moonbitlang/core":
        route_parts = package_parts
    else:
        route_parts = [
            *module_parts[:-1],
            module_parts[-1] + "@" + target.resolved_version,
            *package_parts[len(module_parts) :],
        ]
    path = "/docs/" + "/".join(_encoded_segment(part) for part in route_parts)
    fragment = quote(target.anchor, safe=":-._~")
    return f"https://mooncakes.io{path}#{fragment}"


def _validate_external_target_value(target: ExternalTarget) -> None:
    if not target.external_target_id:
        raise SnapshotError("external target requires a non-empty external_target_id")
    try:
        parsed = urlsplit(target.url)
    except ValueError as exc:
        raise SnapshotError(f"external target {target.external_target_id!r} has an invalid URL") from exc
    if (
        parsed.scheme != "https"
        or parsed.netloc != "mooncakes.io"
        or parsed.query
        or not parsed.fragment
    ):
        raise SnapshotError(f"external target {target.external_target_id!r} has an unsafe Mooncakes URL")
    if target.url != _external_target_url(target):
        raise SnapshotError(
            f"external target {target.external_target_id!r} URL does not match its route fields"
        )


def _external_target(record: Mapping[str, Any]) -> ExternalTarget:
    required = {
        "external_target_id",
        "provider",
        "module",
        "resolved_version",
        "package",
        "anchor",
        "url",
        "status",
    }
    missing = required - record.keys()
    if missing:
        raise SnapshotError(f"external target missing fields: {sorted(missing)}")
    if any(not isinstance(record[field], str) or not record[field] for field in required):
        raise SnapshotError("external target fields must be non-empty strings")
    target = ExternalTarget(
        external_target_id=record["external_target_id"],
        provider=record["provider"],
        module=record["module"],
        requested_version=str(record.get("requested_version") or ""),
        resolved_version=record["resolved_version"],
        package=record["package"],
        anchor=record["anchor"],
        url=record["url"],
        match=str(record.get("match") or ""),
        status=record["status"],
        metadata=dict(record),
    )
    _validate_external_target_value(target)
    return target


def _target(record: Mapping[str, Any]) -> DefinitionTarget:
    source_id = record.get("target_source_id") or record.get("source_id")
    selected = record.get("target_selection_range_utf8") or record.get("selection_range_utf8") or record.get("target_range_utf8")
    if not isinstance(source_id, str):
        raise SnapshotError("definition target requires target_source_id")
    selection = _range(selected, label="definition selection range")
    whole = record.get("target_range_utf8")
    external_target_id = record.get("external_target_id")
    external_status = record.get("external_status")
    if external_target_id is not None and not isinstance(external_target_id, str):
        raise SnapshotError("definition external_target_id must be a string")
    if external_status is not None and not isinstance(external_status, str):
        raise SnapshotError("definition external_status must be a string")
    return DefinitionTarget(
        source_id=source_id,
        selection_range=selection,
        symbol_id=record.get("symbol_id") or record.get("target_symbol_id"),
        target_range=_range(whole, label="definition target range") if whole is not None else selection,
        external_target_id=external_target_id,
        external_status=external_status,
    )


def _validate_definition_external_target(
    definition: DefinitionTarget,
    target_source: Source,
    external_targets: Mapping[str, ExternalTarget],
) -> None:
    if definition.external_status is not None and (
        not isinstance(definition.external_status, str)
        or not definition.external_status
    ):
        raise SnapshotError("definition external_status must be a non-empty string")
    if definition.external_target_id is None:
        if definition.external_status == "exact":
            raise SnapshotError("exact external definition is missing external_target_id")
        return
    if not definition.external_target_id:
        raise SnapshotError("definition external_target_id must be non-empty")
    if definition.external_status != "exact":
        raise SnapshotError("definition external_target_id requires external_status='exact'")
    if target_source.origin in {"local", "standalone"}:
        raise SnapshotError("local/standalone definition target cannot be external")
    target = external_targets.get(definition.external_target_id)
    if target is None or target.status != "exact":
        raise SnapshotError(
            f"definition references missing external target: {definition.external_target_id}"
        )
    if target_source.module and target.module != target_source.module:
        raise SnapshotError(
            "external definition module does not match its target source"
        )
    if (
        target_source.version
        and target.requested_version != target_source.version
    ):
        raise SnapshotError(
            "external definition requested version does not match its target source"
        )


def _occurrence(
    record: Mapping[str, Any],
    default_source_id: str | None = None,
    default_context_id: str | None = None,
) -> Occurrence:
    explicit_source_id = record.get("source_id")
    explicit_context_id = record.get("context_id")
    if (
        default_source_id is not None
        and explicit_source_id is not None
        and explicit_source_id != default_source_id
    ):
        raise SnapshotError(
            "occurrence source_id conflicts with its ledger envelope"
        )
    if (
        default_context_id is not None
        and explicit_context_id is not None
        and explicit_context_id != default_context_id
    ):
        raise SnapshotError(
            "occurrence context_id conflicts with its ledger envelope"
        )
    source_id = (
        default_source_id
        if explicit_source_id is None
        else explicit_source_id
    )
    context_id = (
        default_context_id
        if explicit_context_id is None
        else explicit_context_id
    )
    effective = record.get("effective_range_utf8") or record.get("hover_range_utf8") or record.get("candidate_range_utf8") or record.get("byte_range")
    if not isinstance(source_id, str) or not source_id:
        raise SnapshotError("occurrence requires source_id")
    if context_id is not None and (
        not isinstance(context_id, str) or not context_id
    ):
        raise SnapshotError(
            "occurrence context_id must be a non-empty string"
        )
    preferred_external_target_id = record.get(
        "preferred_external_target_id"
    )
    if preferred_external_target_id is not None and not isinstance(
        preferred_external_target_id, str
    ):
        raise SnapshotError(
            "occurrence preferred_external_target_id must be a string"
        )
    definitions = record.get("definitions") or record.get("targets") or []
    return Occurrence(
        source_id=source_id,
        byte_range=_range(effective, label="occurrence range"),
        context_id=context_id,
        symbol_id=record.get("symbol_id"),
        hover_id=record.get("hover_id"),
        role=str(record.get("role") or record.get("kind") or "reference"),
        definitions=tuple(_target(item) for item in definitions),
        preferred_external_target_id=preferred_external_target_id,
    )


def _records_from_json(path: Path) -> Iterable[Mapping[str, Any]]:
    value = _json(path)
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        records = value.get("occurrences")
        if records is None:
            records = value.get("records")
        if isinstance(records, list):
            return records
        # Hover shards are maps and handled separately.
    raise SnapshotError(f"unsupported record shard shape: {path}")


def _verify_manifest_shards(root: Path, manifest: Mapping[str, Any]) -> set[str]:
    shards = manifest.get("shards") or manifest.get("files") or {}
    if isinstance(shards, list):
        shards = {item["path"]: item.get("sha256") or item.get("digest") for item in shards}
    if not isinstance(shards, Mapping):
        raise SnapshotError("manifest shards must be a mapping or list")
    for name, expected in shards.items():
        if not isinstance(name, str) or not isinstance(expected, str):
            raise SnapshotError("manifest shard entries require string path and digest")
        path = root / _safe_relative(name, label="shard path")
        if not path.is_file():
            raise SnapshotError(f"manifest shard is missing: {name}")
        if _sha256(path.read_bytes()) != _digest_name(expected):
            raise SnapshotError(f"manifest shard digest mismatch: {name}")
    return set(shards)


def load_snapshot(path: str | Path) -> SemanticSnapshot:
    root = Path(path).expanduser().resolve()
    manifest_path = root / "manifest.json"
    if not manifest_path.is_file():
        raise SnapshotError(f"semantic snapshot manifest not found: {manifest_path}")
    try:
        manifest_bytes = manifest_path.read_bytes()
        manifest = json.loads(manifest_bytes)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise SnapshotError(f"cannot read semantic snapshot manifest: {exc}") from exc
    if not isinstance(manifest, dict):
        raise SnapshotError("snapshot manifest must be an object")
    schema = manifest.get("schema_version", manifest.get("schema"))
    if schema not in ACCEPTED_SCHEMAS:
        raise SnapshotError(f"unsupported semantic snapshot schema: {schema!r}")
    verified_shards = _verify_manifest_shards(root, manifest)

    sources: dict[str, Source] = {}
    for record in _jsonl(root / "sources.jsonl", required=True):
        source = _source(record)
        if source.source_id in sources:
            raise SnapshotError(f"duplicate source_id: {source.source_id}")
        sources[source.source_id] = source

    symbols: dict[str, Symbol] = {}
    for record in _jsonl(root / "symbols.jsonl"):
        symbol = _symbol(record)
        if symbol.symbol_id in symbols:
            raise SnapshotError(f"duplicate symbol_id: {symbol.symbol_id}")
        symbols[symbol.symbol_id] = symbol

    assets: dict[str, Asset] = {}
    for record in _jsonl(root / "assets.jsonl"):
        asset = _asset(record)
        if asset.asset_id in assets:
            raise SnapshotError(f"duplicate asset_id: {asset.asset_id}")
        assets[asset.asset_id] = asset

    external_path = root / EXTERNAL_TARGET_TABLE
    if external_path.exists() and EXTERNAL_TARGET_TABLE not in verified_shards:
        raise SnapshotError("external target table is not covered by the manifest")
    external_targets: dict[str, ExternalTarget] = {}
    for record in _jsonl(external_path):
        target = _external_target(record)
        if target.external_target_id in external_targets:
            raise SnapshotError(
                f"duplicate external_target_id: {target.external_target_id}"
            )
        external_targets[target.external_target_id] = target

    occurrences_by_context: dict[str, dict[str, list[Occurrence]]] = {}
    occurrence_root = root / "occurrences"
    if occurrence_root.is_dir():
        for shard in sorted(occurrence_root.rglob("*.json")):
            payload = _json(shard)
            if isinstance(payload, dict) and isinstance(
                payload.get("occurrences"), list
            ):
                source_id = payload.get("source_id")
                context_id = payload.get("context_id")
                if (source_id is None) != (context_id is None):
                    raise SnapshotError(
                        f"occurrence ledger has partial source/context identity: {shard}"
                    )
                records = payload["occurrences"]
                if (
                    isinstance(source_id, str)
                    and source_id
                    and isinstance(context_id, str)
                    and context_id
                ):
                    if source_id not in sources:
                        raise SnapshotError(
                            f"occurrence ledger has unknown source: {shard}"
                        )
                    occurrences_by_context.setdefault(source_id, {}).setdefault(
                        context_id, []
                    )
                    envelope_context_id = context_id
                else:
                    if source_id is not None or context_id is not None:
                        raise SnapshotError(
                            f"occurrence ledger identity must be strings: {shard}"
                        )
                    source_id = None
                    envelope_context_id = None
            else:
                records = _records_from_json(shard)
                source_id = None
                envelope_context_id = None
            for record in records:
                occurrence = _occurrence(
                    record, source_id, envelope_context_id
                )
                if occurrence.source_id not in sources:
                    raise SnapshotError(
                        "occurrence targets unknown source: "
                        f"{occurrence.source_id}"
                    )
                context = occurrence.context_id or ""
                occurrences_by_context.setdefault(occurrence.source_id, {}).setdefault(context, []).append(occurrence)
    for record in _jsonl(root / "occurrences.jsonl"):
        occurrence = _occurrence(record)
        context = occurrence.context_id or ""
        occurrences_by_context.setdefault(occurrence.source_id, {}).setdefault(context, []).append(occurrence)

    occurrences: dict[str, list[Occurrence]] = {}
    for source_id in sources:
        contexts = occurrences_by_context.get(source_id, {})
        preferred = sources[source_id].context_id
        if preferred:
            if preferred not in contexts:
                raise SnapshotError(
                    f"source canonical context has no occurrence ledger: {source_id}"
                )
            selected = contexts[preferred]
        elif contexts:
            # Schema v1 snapshots predating canonical contexts may contain
            # several ledgers for one source.  Preserve their deterministic
            # historical fallback while new snapshots select explicitly.
            selected = contexts[sorted(contexts)[0]]
        else:
            selected = []
        unique: dict[tuple[Any, ...], Occurrence] = {}
        for item in selected or []:
            targets = tuple(
                (
                    target.source_id,
                    target.selection_range,
                    target.symbol_id,
                    target.external_target_id,
                    target.external_status,
                )
                for target in item.definitions
            )
            unique[
                (
                    item.byte_range,
                    item.hover_id,
                    item.symbol_id,
                    item.role,
                    targets,
                    item.preferred_external_target_id,
                )
            ] = item
        occurrences[source_id] = list(unique.values())

    # Ensure every definition is rendered even when the provider emitted no
    # separate definition occurrence.
    known_definition_spans = {
        (item.source_id, item.symbol_id, item.byte_range) for values in occurrences.values() for item in values
    }
    for symbol in symbols.values():
        key = (symbol.source_id, symbol.symbol_id, symbol.byte_range)
        if key not in known_definition_spans:
            occurrences.setdefault(symbol.source_id, []).append(
                Occurrence(
                    source_id=symbol.source_id,
                    byte_range=symbol.byte_range,
                    symbol_id=symbol.symbol_id,
                    hover_id=symbol.hover_id,
                    role="definition",
                    definitions=(DefinitionTarget(symbol.source_id, symbol.byte_range, symbol.symbol_id),),
                )
            )

    hovers: dict[str, Any] = {}
    hover_root = root / "hovers"
    if hover_root.is_dir():
        for shard in sorted(hover_root.rglob("*.json")):
            value = _json(shard)
            if isinstance(value, dict) and "hover_id" in value:
                payload = {key: item for key, item in value.items() if key != "hover_id"}
                hovers[str(value["hover_id"])] = value.get("contents", value.get("markdown", payload))
            elif isinstance(value, dict):
                hovers.update(value)
            elif isinstance(value, list):
                for item in value:
                    if isinstance(item, dict) and "hover_id" in item:
                        hovers[str(item["hover_id"])] = item.get("contents", item.get("markdown", ""))

    corpus = str(manifest.get("corpus_digest") or _sha256(manifest_path.read_bytes()))
    snapshot = SemanticSnapshot(
        root=root,
        manifest=manifest,
        sources=sources,
        assets=assets,
        symbols=symbols,
        occurrences={key: tuple(sorted(values, key=lambda item: (item.byte_range, item.symbol_id or ""))) for key, values in occurrences.items()},
        hovers=hovers,
        corpus_digest=corpus,
        external_targets=external_targets,
    )
    snapshot.validate()
    try:
        if manifest_path.read_bytes() != manifest_bytes:
            raise SnapshotError("semantic snapshot changed while it was being loaded")
    except OSError as exc:
        raise SnapshotError("semantic snapshot disappeared while it was being loaded") from exc
    return snapshot
