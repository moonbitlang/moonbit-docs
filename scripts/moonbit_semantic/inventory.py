"""Source-root, package-metadata, dependency, and stdlib inventory."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

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
            roots[path] = Root(path, "standalone:" + relative, "required", "standalone", "", backend, literate.resolve())
    return sorted(roots.values(), key=lambda root: root.root_id)


def package_metadata(root: Root) -> tuple[dict[str, Any] | None, Path | None]:
    candidates = [root.path / "_build" / "packages.json"]
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
