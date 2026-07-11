"""Source-root, package-metadata, dependency, and stdlib inventory."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping

from .canonical import digest_bytes, is_within, normalize_relative, realpath
from .literate import extract_literate_fences

SOURCE_SUFFIXES = (".mbt.md", ".mbt", ".mbti", ".mbtp")
EXCLUDED_DIRS = {".git", ".hg", ".svn", "_build", "target", "node_modules"}


@dataclass(frozen=True)
class Root:
    path: Path
    root_id: str
    status: str
    module_name: str
    version: str
    backend: str
    entry_file: Path | None = None


@dataclass(frozen=True)
class PackageOwnership:
    """One ``packages.json`` context's physical-to-logical package index.

    The tuples deliberately contain only ``Path`` and ``str`` values so the
    index can be copied to analysis workers and exercised without a live Moon
    process.  Callers must build one instance per package-metadata context;
    ownership is never inferred from another context or from a global cache.

    ``resolve`` fails closed for both missing and ambiguous ownership.  An
    exact production-file declaration wins over directory ancestry.  When no
    exact declaration exists, the deepest matching package root wins.
    """

    file_owners: tuple[tuple[Path, str], ...] = ()
    root_owners: tuple[tuple[Path, str], ...] = ()

    def resolve(self, target: str | Path) -> str | None:
        location = self.resolve_location(target)
        return location[0] if location is not None else None

    def resolve_location(self, target: str | Path) -> tuple[str, str] | None:
        """Return the logical package and its package-relative POSIX file."""

        path = realpath(Path(target))
        exact = {
            package for candidate, package in self.file_owners if candidate == path
        }
        if exact:
            if len(exact) != 1:
                return None
            return self._location(path, next(iter(exact)))

        matches: list[tuple[int, Path, str]] = []
        for root, package in self.root_owners:
            try:
                path.relative_to(root)
            except ValueError:
                continue
            matches.append((len(root.parts), root, package))
        if not matches:
            return None
        longest = max(depth for depth, _root, _package in matches)
        packages = {
            package for depth, _root, package in matches if depth == longest
        }
        if len(packages) != 1:
            return None
        return self._location(path, next(iter(packages)))

    def _location(self, path: Path, package: str) -> tuple[str, str] | None:
        containing: set[Path] = set()
        for root, owner in self.root_owners:
            if owner != package:
                continue
            try:
                path.relative_to(root)
            except ValueError:
                continue
            containing.add(root)
        if not containing:
            return None
        longest = max(len(root.parts) for root in containing)
        roots = {root for root in containing if len(root.parts) == longest}
        if len(roots) != 1:
            return None
        root = next(iter(roots))
        return package, path.relative_to(root).as_posix()


def _package_path(root: Any, relative: Any) -> str | None:
    if not isinstance(root, str) or not root.strip("/"):
        return None
    root = root.strip("/")
    if not isinstance(relative, str) or relative.strip("/") in {"", "."}:
        return root
    return root + "/" + relative.strip("/")


def _metadata_path(value: Any, base: Path | None = None) -> Path | None:
    if not isinstance(value, (str, Path)) or not str(value):
        return None
    path = Path(value)
    if not path.is_absolute() and base is not None:
        path = base / path
    return realpath(path)


def _metadata_file_paths(value: Any) -> Iterable[Any]:
    if isinstance(value, Mapping):
        return value.keys()
    if isinstance(value, (list, tuple)):
        return value
    return ()


def metadata_package_ownership(metadata: dict[str, Any]) -> PackageOwnership:
    """Build a context-local ownership index from Moon's ``packages.json``.

    Package records are authoritative: ``root`` plus ``rel`` supplies the
    logical package, ``root-path`` its physical root, and ``files`` its exact
    production-file set.  Dependency records supplement the root index using
    their logical ``path`` and physical ``fspath``.  No module-version parsing,
    checkout scanning, or cross-context fallback is performed here.
    """

    source_dir = _metadata_path(metadata.get("source_dir"))
    package_roots: list[tuple[Path, str]] = []
    file_owners: set[tuple[Path, str]] = set()
    root_owners: set[tuple[Path, str]] = set()
    package_records = metadata.get("packages")
    if not isinstance(package_records, list):
        package_records = []

    for record in package_records:
        if not isinstance(record, Mapping):
            continue
        package = _package_path(record.get("root"), record.get("rel"))
        root = _metadata_path(
            record.get("root-path", record.get("root_path")), source_dir
        )
        if package is None or root is None:
            continue
        package_roots.append((root, package))
        root_owners.add((root, package))
        for value in _metadata_file_paths(record.get("files")):
            path = _metadata_path(value, root)
            if path is not None:
                file_owners.add((path, package))

    roots_by_package: dict[str, set[Path]] = {}
    packages_by_root: dict[Path, set[str]] = {}
    for root, package in package_roots:
        roots_by_package.setdefault(package, set()).add(root)
        packages_by_root.setdefault(root, set()).add(package)

    dependency_records: list[Any] = []
    for record in package_records:
        if not isinstance(record, Mapping):
            continue
        for key in (
            "deps",
            "wbtest-deps",
            "wbtest_deps",
            "test-deps",
            "test_deps",
        ):
            value = record.get(key)
            if isinstance(value, list):
                dependency_records.extend(value)
    top_level_dependencies = metadata.get("deps")
    if isinstance(top_level_dependencies, list):
        dependency_records.extend(top_level_dependencies)

    for dependency in dependency_records:
        if not isinstance(dependency, Mapping):
            continue
        raw_package = dependency.get("path")
        package = (
            raw_package.strip("/")
            if isinstance(raw_package, str) and raw_package.strip("/")
            else None
        )
        root = _metadata_path(dependency.get("fspath"), source_dir)

        # Older or synthetic metadata may omit one half of the pair.  Use an
        # unambiguous authoritative package record as the fallback; never guess
        # from another ``packages.json`` context.
        if root is None and package is not None:
            candidates = roots_by_package.get(package, set())
            if len(candidates) == 1:
                root = next(iter(candidates))
        if package is None and root is not None:
            candidates = packages_by_root.get(root, set())
            if len(candidates) == 1:
                package = next(iter(candidates))
        if package is not None and root is not None:
            root_owners.add((root, package))

    def order(item: tuple[Path, str]) -> tuple[str, str]:
        return item[0].as_posix(), item[1]

    return PackageOwnership(
        file_owners=tuple(sorted(file_owners, key=order)),
        root_owners=tuple(sorted(root_owners, key=order)),
    )


def discover_roots(source_root: Path, backend: str) -> list[Root]:
    roots: dict[Path, Root] = {}
    for manifest in sorted(_walk_manifests(source_root)):
        path = manifest.parent.resolve()
        identity = _module_identity(path)
        relative = normalize_relative(path.relative_to(source_root.resolve())) or "."
        status = "expected-failure" if _is_expected_failure(path) else "required"
        root_id = "root:" + relative
        roots[path] = Root(path, root_id, status, identity[0], identity[1], identity[2] or backend)
    for literate in sorted(source_root.rglob("*.mbt.md")):
        if any(part in EXCLUDED_DIRS or part == ".mooncakes" for part in literate.parts):
            continue
        if not any(is_within(literate, root.path) for root in roots.values()):
            path = literate.parent.resolve()
            relative = normalize_relative(literate.resolve().relative_to(source_root.resolve()))
            # moon-lsp creates loose-file `.mbt.md` contexts for the native
            # backend and exposes no initialize option to override it.  Match
            # the check barrier to that real provider context so its generated
            # packages metadata remains stable across analysis.
            roots[path] = Root(
                path,
                "standalone:" + relative,
                "required",
                "standalone",
                "",
                "native",
                literate.resolve(),
            )
    return sorted(roots.values(), key=lambda root: root.root_id)


def package_metadata(root: Root) -> tuple[dict[str, Any] | None, Path | None]:
    candidates = [root.path / "_build" / "packages.json"]
    # `moon check -C <workspace-member>` writes the IDE package graph into
    # the nearest `moon.work` owner's shared `_build`, not necessarily below
    # the member module itself.  Resolve that location explicitly instead of
    # walking arbitrary ancestor build directories.
    workspace = _nearest_workspace(root.path)
    if workspace is not None:
        candidates.append(workspace / "_build" / "packages.json")
    if root.root_id.startswith("standalone:"):
        candidates.extend(sorted((root.path / "_build").glob("*.packages.json")))
    for candidate in candidates:
        if candidate.is_file():
            try:
                value = json.loads(candidate.read_text(encoding="utf-8"))
                return value, candidate
            except (OSError, UnicodeDecodeError, json.JSONDecodeError):
                return None, candidate
    return None, None


def _nearest_workspace(path: Path) -> Path | None:
    for candidate in (path.resolve(), *path.resolve().parents):
        if (candidate / "moon.work").is_file():
            return candidate
    return None


def metadata_sources(metadata: dict[str, Any]) -> set[Path]:
    result: set[Path] = set()
    for package in metadata.get("packages", []):
        for key in ("files", "wbtest-files", "test-files", "mbt-md-files"):
            value = package.get(key, {})
            paths = value.keys() if isinstance(value, dict) else value if isinstance(value, list) else []
            for path in paths:
                candidate = Path(path)
                if candidate.is_file() and recognized(candidate):
                    result.add(realpath(candidate))
    return result


def metadata_allowed_module_roots(metadata: dict[str, Any], stdlib_root: Path | None) -> set[Path]:
    roots: set[Path] = set()
    for package in metadata.get("packages", []):
        for key in ("deps", "wbtest-deps", "test-deps"):
            for dep in package.get(key, []) or []:
                fspath = dep.get("fspath") if isinstance(dep, dict) else None
                if not fspath:
                    continue
                path = realpath(Path(fspath))
                if stdlib_root and is_within(path, stdlib_root):
                    continue
                module = _ascend_module_root(path)
                if module:
                    roots.add(module)
    for dep in metadata.get("deps", []) or []:
        if isinstance(dep, dict) and dep.get("fspath"):
            module = _ascend_module_root(Path(dep["fspath"]))
            if module:
                roots.add(module)
    return roots


def scan_sources(root: Path, *, include_hidden_mooncakes: bool = False) -> list[Path]:
    root = realpath(root)
    result: list[Path] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or not recognized(path):
            continue
        relative_parts = path.relative_to(root).parts
        if any(part in EXCLUDED_DIRS for part in relative_parts):
            continue
        if not include_hidden_mooncakes and ".mooncakes" in relative_parts:
            continue
        resolved = realpath(path)
        if not is_within(resolved, root):
            raise ValueError(f"source symlink escapes root: {path}")
        result.append(resolved)
    return result


def make_source(path: Path, *, origin: str, base: Path, module: str, version: str, status: str) -> dict[str, Any]:
    path = realpath(path)
    base = realpath(base)
    relative = normalize_relative(path.relative_to(base))
    raw = path.read_bytes()
    kind = next(suffix.removeprefix(".") for suffix in SOURCE_SUFFIXES if path.name.endswith(suffix))
    module_identity = module or "unknown"
    if origin == "local":
        source_id = f"local:{relative}"
    elif origin == "standalone":
        source_id = f"standalone:{relative}"
    elif origin == "stdlib":
        source_id = f"stdlib:{module_identity}@{version}:{relative}"
    else:
        source_id = f"dependency:{module_identity}@{version or digest_bytes(module_identity.encode())[7:19]}:{relative}"
    analysis_status = status
    if kind in {"mbti", "mbtp"}:
        analysis_status = "display-only"
    source = {
        "source_id": source_id,
        "origin": origin,
        "module": module_identity,
        "version": version,
        "path": relative,
        "kind": kind,
        "blob_digest": digest_bytes(raw),
        "analysis_status": analysis_status,
        "route_key": _route_key(origin, module_identity, version, relative),
        "_realpath": str(path),
        "_blob": raw,
    }
    if kind == "mbt.md":
        source["literate_fences"] = extract_literate_fences(raw)
    return source


def module_info(root: Path) -> dict[str, str]:
    name, version, preferred_target = _module_identity(root)
    license_name = ""
    repository = ""
    for filename in ("moon.mod.json", "moon.mod"):
        path = root / filename
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        if filename.endswith("json"):
            try:
                value = json.loads(text)
                license_name = str(value.get("license", ""))
                repository = str(value.get("repository", ""))
            except json.JSONDecodeError:
                pass
        else:
            license_name = _tomlish(text, "license")
            repository = _tomlish(text, "repository")
    return {"name": name, "version": version, "license": license_name, "repository": repository, "preferred_target": preferred_target}


def recognized(path: Path) -> bool:
    return any(path.name.endswith(suffix) for suffix in SOURCE_SUFFIXES)


def _walk_manifests(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.name not in {"moon.work", "moon.mod", "moon.mod.json"}:
            continue
        relative = path.relative_to(root)
        if any(part in EXCLUDED_DIRS or part == ".mooncakes" for part in relative.parts):
            continue
        yield path


def _ascend_module_root(path: Path) -> Path | None:
    current = realpath(path if path.is_dir() else path.parent)
    for candidate in (current, *current.parents):
        if any((candidate / name).is_file() for name in ("moon.mod.json", "moon.mod")):
            return candidate
        if candidate.name == ".mooncakes":
            break
    return None


def _module_identity(root: Path) -> tuple[str, str, str]:
    for filename in ("moon.mod.json", "moon.mod"):
        path = root / filename
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        if filename.endswith("json"):
            try:
                value = json.loads(text)
                return str(value.get("name", root.name)), str(value.get("version", "")), str(value.get("preferred-target", value.get("preferred_target", "")))
            except json.JSONDecodeError:
                return root.name, "", ""
        return _tomlish(text, "name") or root.name, _tomlish(text, "version"), _tomlish(text, "preferred_target")
    return root.name, "", ""


def _tomlish(text: str, field: str) -> str:
    match = re.search(rf'^\s*{re.escape(field)}\s*=\s*"([^"]*)"', text, re.MULTILINE)
    return match.group(1) if match else ""


def _is_expected_failure(path: Path) -> bool:
    return "error_codes" in path.parts and path.name.endswith("_error")


def _route_key(origin: str, module: str, version: str, relative: str) -> str:
    safe_module = "/".join(part.replace("%", "%25").replace("@", "%40") for part in module.split("/"))
    version_part = (version or "unversioned").replace("/", "%2F")
    return f"{origin}/{safe_module}/{version_part}/{relative}"
