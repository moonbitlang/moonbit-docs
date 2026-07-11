"""Atomic semantic snapshot writer and strict, standalone validator."""

from __future__ import annotations

import json
import os
import shutil
import tempfile
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import quote, urlsplit

from .canonical import canonical_json_bytes, digest_bytes, digest_json, normalize_relative, write_json, write_jsonl

SCHEMA = "moonbit-semantic-snapshot/v1"
JSONL_TABLES = (
    "analysis-inputs.jsonl", "sources.jsonl", "assets.jsonl", "contexts.jsonl",
    "symbols.jsonl", "diagnostics.jsonl",
)
EXTERNAL_TARGET_TABLE = "external-targets.jsonl"


class SnapshotError(RuntimeError):
    pass


class SnapshotWriter:
    def __init__(self, output: Path):
        self.output = output.resolve()
        self.parent = self.output.parent
        self.parent.mkdir(parents=True, exist_ok=True)
        self.temp = Path(tempfile.mkdtemp(prefix=f".{self.output.name}.", dir=self.parent))

    def write_blob(self, raw: bytes) -> str:
        digest = digest_bytes(raw)
        path = self.temp / "blobs" / "sha256" / digest.removeprefix("sha256:")
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_bytes(raw)
        return digest

    def write_table(self, name: str, rows: Iterable[dict[str, Any]], sort_fields: tuple[str, ...]) -> None:
        write_jsonl(self.temp / name, rows, key=lambda row: tuple(str(row.get(field, "")) for field in sort_fields))

    def write_shard(self, name: str, value: Any) -> None:
        path = normalize_relative(name)
        write_json(self.temp / path, value)

    def publish(self, metadata: dict[str, Any]) -> dict[str, Any]:
        files: list[dict[str, Any]] = []
        for path in sorted(self.temp.rglob("*")):
            if path.is_file() and path.name != "manifest.json":
                rel = path.relative_to(self.temp).as_posix()
                raw = path.read_bytes()
                files.append({"path": rel, "digest": digest_bytes(raw), "size": len(raw)})
        corpus_digest = digest_json(files)
        manifest = {
            "schema": SCHEMA,
            "analyzer": metadata["analyzer"],
            "backend": metadata["backend"],
            "toolchain": metadata["toolchain"],
            "resolution_digest": metadata["resolution_digest"],
            "corpus_digest": corpus_digest,
            "counts": metadata["counts"],
            "partial": bool(metadata.get("partial", False)),
            "files": files,
        }
        if metadata.get("analysis") is not None:
            manifest["analysis"] = metadata["analysis"]
        write_json(self.temp / "manifest.json", manifest)
        validate_snapshot(self.temp)
        previous = self.output.with_name(self.output.name + ".previous")
        if previous.exists():
            shutil.rmtree(previous)
        try:
            if self.output.exists():
                os.replace(self.output, previous)
            os.replace(self.temp, self.output)
        except BaseException:
            if not self.output.exists() and previous.exists():
                os.replace(previous, self.output)
            raise
        else:
            if previous.exists():
                shutil.rmtree(previous)
        return manifest

    def abort(self) -> None:
        shutil.rmtree(self.temp, ignore_errors=True)


def validate_snapshot(root: Path) -> dict[str, Any]:
    root = root.resolve()
    manifest_path = root / "manifest.json"
    if not manifest_path.is_file():
        raise SnapshotError("missing manifest.json")
    manifest = _json(manifest_path)
    if manifest.get("schema") != SCHEMA:
        raise SnapshotError(f"unsupported schema: {manifest.get('schema')!r}")
    required = {"analyzer", "backend", "toolchain", "resolution_digest", "corpus_digest", "counts", "partial", "files"}
    missing = required - manifest.keys()
    if missing:
        raise SnapshotError(f"manifest missing fields: {sorted(missing)}")
    actual_files: list[dict[str, Any]] = []
    listed = set()
    for entry in manifest["files"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("path"), str):
            raise SnapshotError("invalid file manifest entry")
        rel = normalize_relative(entry["path"])
        if rel in listed or rel == "manifest.json":
            raise SnapshotError(f"duplicate or forbidden manifest path: {rel}")
        listed.add(rel)
        path = root / rel
        if not path.is_file():
            raise SnapshotError(f"missing snapshot file: {rel}")
        raw = path.read_bytes()
        actual = {"path": rel, "digest": digest_bytes(raw), "size": len(raw)}
        if actual != entry:
            raise SnapshotError(f"digest/size mismatch: {rel}")
        actual_files.append(actual)
    actual_on_disk = {p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and p.name != "manifest.json"}
    if listed != actual_on_disk:
        raise SnapshotError(f"unlisted snapshot files: {sorted(actual_on_disk - listed)}")
    if digest_json(actual_files) != manifest["corpus_digest"]:
        raise SnapshotError("corpus digest mismatch")
    for table in JSONL_TABLES:
        if table not in listed:
            raise SnapshotError(f"missing table: {table}")
    if "resolution-lock.json" not in listed:
        raise SnapshotError("missing resolution-lock.json")
    resolution = _json(root / "resolution-lock.json")
    if digest_json(resolution) != manifest["resolution_digest"]:
        raise SnapshotError("resolution digest mismatch")
    sources = _jsonl(root / "sources.jsonl")
    analysis_inputs = _jsonl(root / "analysis-inputs.jsonl")
    assets = _jsonl(root / "assets.jsonl")
    contexts = _jsonl(root / "contexts.jsonl")
    symbols = _jsonl(root / "symbols.jsonl")
    external_targets = (
        _jsonl(root / EXTERNAL_TARGET_TABLE)
        if EXTERNAL_TARGET_TABLE in listed
        else []
    )
    source_ids = _unique(sources, "source_id")
    context_ids = _unique(contexts, "context_id")
    symbol_ids = _unique(symbols, "symbol_id")
    external_target_ids = (
        _unique(external_targets, "external_target_id")
        if external_targets
        else set()
    )
    source_by_id = {source["source_id"]: source for source in sources}
    context_by_id = {context["context_id"]: context for context in contexts}
    symbol_by_id = {symbol["symbol_id"]: symbol for symbol in symbols}
    external_target_by_id = {
        target["external_target_id"]: target for target in external_targets
    }
    for target in external_targets:
        _validate_external_target(target)
    source_blobs: dict[str, bytes] = {}
    boundaries: dict[str, set[int]] = {}
    for source in sources:
        _require(source, {"source_id", "origin", "path", "kind", "blob_digest", "analysis_status", "route_key"}, "source")
        digest = source["blob_digest"]
        if not isinstance(digest, str) or not digest.startswith("sha256:"):
            raise SnapshotError(f"invalid blob digest for {source.get('source_id')}")
        blob_path = root / "blobs" / "sha256" / digest.removeprefix("sha256:")
        if not blob_path.is_file() or digest_bytes(blob_path.read_bytes()) != digest:
            raise SnapshotError(f"missing/corrupt blob: {digest}")
        raw = blob_path.read_bytes()
        source_blobs[source["source_id"]] = raw
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise SnapshotError(f"source blob is not UTF-8: {source['source_id']}") from exc
        offset = 0
        valid = {0}
        for character in text:
            offset += len(character.encode("utf-8"))
            valid.add(offset)
        boundaries[source["source_id"]] = valid
    for item in analysis_inputs:
        _require(item, {"root_id", "kind", "path", "blob_digest"}, "analysis input")
        _validate_blob(root, item["blob_digest"], f"analysis input {item['path']}")
    asset_ids = _unique(assets, "asset_id") if assets else set()
    del asset_ids
    for asset in assets:
        _require(asset, {"asset_id", "owner_source_id", "path", "blob_digest", "mime"}, "asset")
        if asset["owner_source_id"] not in source_ids:
            raise SnapshotError(f"asset owner missing: {asset['asset_id']}")
        _validate_blob(root, asset["blob_digest"], f"asset {asset['asset_id']}")
    for context in contexts:
        _require(context, {"context_id", "root_id", "backend", "input_source_ids", "context_input_digest"}, "context")
        unknown = set(context["input_source_ids"]) - source_ids
        if unknown:
            raise SnapshotError(f"context references unknown sources: {sorted(unknown)}")
        analysis_source_ids = context.get(
            "analysis_source_ids", context["input_source_ids"]
        )
        if not isinstance(analysis_source_ids, list):
            raise SnapshotError(
                f"context analysis source ids must be a list: {context['context_id']}"
            )
        analysis_unknown = set(analysis_source_ids) - set(context["input_source_ids"])
        if analysis_unknown:
            raise SnapshotError(
                f"context analysis sources are outside its inputs: {sorted(analysis_unknown)}"
            )
        if {item.get("source_id") for item in context.get("input_blobs", [])} != set(context["input_source_ids"]):
            raise SnapshotError(f"context input blob ledger mismatch: {context['context_id']}")
        ledger = {item.get("source_id"): item.get("blob_digest") for item in context.get("input_blobs", [])}
        expected_ledger = {source_id: source_by_id[source_id]["blob_digest"] for source_id in context["input_source_ids"]}
        if ledger != expected_ledger:
            raise SnapshotError(f"context input digests mismatch: {context['context_id']}")
        fingerprint = {
            "root_id": context["root_id"], "module": context.get("package", ""),
            "backend": context["backend"], "toolchain": digest_json(manifest["toolchain"]),
            "inputs": context["input_blobs"],
        }
        if "analysis_source_ids" in context:
            fingerprint["analysis"] = {
                "origins": context.get("analysis_origins", []),
                "source_ids": analysis_source_ids,
            }
        if digest_json(fingerprint) != context["context_input_digest"]:
            raise SnapshotError(f"context digest mismatch: {context['context_id']}")
    hover_ids: set[str] = set()
    for path in sorted((root / "hovers").glob("*.json")) if (root / "hovers").exists() else []:
        hover = _json(path)
        _require(hover, {"hover_id", "kind", "value"}, "hover")
        hover_id = hover["hover_id"]
        if not isinstance(hover_id, str) or hover_id in hover_ids:
            raise SnapshotError(f"missing or duplicate hover_id: {hover_id!r}")
        if digest_json({"kind": hover["kind"], "value": hover["value"]}) != hover_id:
            raise SnapshotError(f"hover digest mismatch: {hover_id}")
        hover_ids.add(hover_id)
    for symbol in symbols:
        _require(symbol, {"symbol_id", "definition_source_id", "selection_range_utf8"}, "symbol")
        if symbol["definition_source_id"] not in source_ids:
            raise SnapshotError(f"symbol target source missing: {symbol['symbol_id']}")
        _validate_range(symbol["selection_range_utf8"], symbol["definition_source_id"], source_blobs, boundaries, "symbol selection")
        if "target_range_utf8" in symbol:
            _validate_range(symbol["target_range_utf8"], symbol["definition_source_id"], source_blobs, boundaries, "symbol target")
        if symbol.get("hover_id") is not None and symbol["hover_id"] not in hover_ids:
            raise SnapshotError(f"symbol hover missing: {symbol['symbol_id']}")
    occurrence_ledgers: set[tuple[str, str]] = set()
    occurrence_count = 0
    for path in sorted((root / "occurrences").glob("*/*.json")) if (root / "occurrences").exists() else []:
        payload = _json(path)
        if payload.get("context_id") not in context_ids or payload.get("source_id") not in source_ids:
            raise SnapshotError(f"invalid occurrence shard identity: {path.relative_to(root)}")
        identity = (payload["context_id"], payload["source_id"])
        if identity in occurrence_ledgers:
            raise SnapshotError(f"duplicate occurrence ledger: {identity}")
        occurrence_ledgers.add(identity)
        if payload["source_id"] not in context_by_id[payload["context_id"]]["input_source_ids"]:
            raise SnapshotError(f"occurrence source is outside context: {path.relative_to(root)}")
        analysis_sources = context_by_id[payload["context_id"]].get(
            "analysis_source_ids",
            context_by_id[payload["context_id"]]["input_source_ids"],
        )
        if payload["source_id"] not in analysis_sources:
            raise SnapshotError(f"occurrence source is outside analysis scope: {path.relative_to(root)}")
        for occurrence in payload.get("occurrences", []):
            occurrence_count += 1
            if occurrence.get("context_id") != payload["context_id"] or occurrence.get("source_id") != payload["source_id"]:
                raise SnapshotError(f"occurrence record identity mismatch: {path.relative_to(root)}")
            for field in ("candidate_range_utf8", "effective_range_utf8"):
                _validate_range(occurrence.get(field), payload["source_id"], source_blobs, boundaries, field)
            if occurrence.get("hover_range_utf8") is not None:
                _validate_range(occurrence["hover_range_utf8"], payload["source_id"], source_blobs, boundaries, "hover range")
            if occurrence.get("hover_id") is not None and occurrence["hover_id"] not in hover_ids:
                raise SnapshotError(f"occurrence hover missing in {path.relative_to(root)}")
            for definition in occurrence.get("definitions", []):
                target_id = definition.get("target_source_id")
                if target_id not in source_ids:
                    raise SnapshotError(f"definition target missing in {path.relative_to(root)}")
                symbol_id = definition.get("symbol_id")
                if symbol_id not in symbol_ids or symbol_by_id[symbol_id]["definition_source_id"] != target_id:
                    raise SnapshotError(f"definition symbol missing/mismatched in {path.relative_to(root)}")
                for field in ("target_range_utf8", "target_selection_range_utf8"):
                    _validate_range(definition.get(field), target_id, source_blobs, boundaries, field)
                if definition.get("origin_selection_range_utf8") is not None:
                    _validate_range(definition["origin_selection_range_utf8"], payload["source_id"], source_blobs, boundaries, "origin selection")
                _validate_definition_external_target(
                    definition,
                    source_by_id[target_id],
                    external_target_by_id,
                )
    request_ledgers: set[tuple[str, str]] = set()
    request_count = 0
    for path in sorted((root / "requests").glob("*/*.json")) if (root / "requests").exists() else []:
        payload = _json(path)
        if payload.get("context_id") not in context_ids or payload.get("source_id") not in source_ids:
            raise SnapshotError(f"invalid request shard identity: {path.relative_to(root)}")
        identity = (payload["context_id"], payload["source_id"])
        if identity in request_ledgers:
            raise SnapshotError(f"duplicate request ledger: {identity}")
        request_ledgers.add(identity)
        if payload["source_id"] not in context_by_id[payload["context_id"]]["input_source_ids"]:
            raise SnapshotError(f"request source is outside context: {path.relative_to(root)}")
        analysis_sources = context_by_id[payload["context_id"]].get(
            "analysis_source_ids",
            context_by_id[payload["context_id"]]["input_source_ids"],
        )
        if payload["source_id"] not in analysis_sources:
            raise SnapshotError(f"request source is outside analysis scope: {path.relative_to(root)}")
        allowed = {"complete", "valid-no-result", "skipped-with-reason"}
        if manifest["partial"]:
            allowed.add("error")
        invalid = [item.get("status") for item in payload.get("requests", []) if item.get("status") not in allowed]
        if invalid:
            raise SnapshotError(f"incomplete semantic requests in {path.relative_to(root)}: {invalid}")
        request_count += len(payload.get("requests", []))
        for request in payload.get("requests", []):
            if request.get("candidate_range_utf8") is not None:
                _validate_range(request["candidate_range_utf8"], payload["source_id"], source_blobs, boundaries, "request candidate")
    required_ledgers = {
        (context["context_id"], source_id)
        for context in contexts if context.get("analysis_status") == "required"
        for source_id in context.get(
            "analysis_source_ids", context["input_source_ids"]
        )
        if source_by_id[source_id]["kind"] in {"mbt", "mbt.md"}
        and source_by_id[source_id]["analysis_status"] != "display-only"
    }
    if not required_ledgers <= request_ledgers or not required_ledgers <= occurrence_ledgers:
        missing_requests = sorted(required_ledgers - request_ledgers)
        missing_occurrences = sorted(required_ledgers - occurrence_ledgers)
        raise SnapshotError(f"missing required ledgers: requests={missing_requests}, occurrences={missing_occurrences}")
    expected = manifest["counts"]
    actual_counts = {
        "sources": len(sources), "contexts": len(contexts), "symbols": len(symbols),
        "assets": len(assets), "hovers": len(hover_ids), "occurrences": occurrence_count,
        "requests": request_count,
    }
    if external_targets or "external_targets" in expected:
        actual_counts["external_targets"] = len(external_target_ids)
    if any(expected.get(key) != value for key, value in actual_counts.items()):
        raise SnapshotError("manifest counts do not match tables")
    return manifest


def _json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SnapshotError(f"invalid JSON: {path}") from exc


def _jsonl(path: Path) -> list[dict[str, Any]]:
    result = []
    try:
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            value = json.loads(line)
            if not isinstance(value, dict):
                raise SnapshotError(f"non-object JSONL record: {path}:{number}")
            result.append(value)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SnapshotError(f"invalid JSONL: {path}") from exc
    return result


def _unique(rows: list[dict[str, Any]], field: str) -> set[str]:
    values = [row.get(field) for row in rows]
    if any(not isinstance(value, str) or not value for value in values) or len(values) != len(set(values)):
        raise SnapshotError(f"missing or duplicate {field}")
    return set(values)


def _require(value: dict[str, Any], fields: set[str], kind: str) -> None:
    missing = fields - value.keys()
    if missing:
        raise SnapshotError(f"{kind} missing fields: {sorted(missing)}")


def _validate_blob(root: Path, digest: Any, owner: str) -> None:
    if not isinstance(digest, str) or not digest.startswith("sha256:"):
        raise SnapshotError(f"invalid blob digest for {owner}")
    path = root / "blobs" / "sha256" / digest.removeprefix("sha256:")
    if not path.is_file() or digest_bytes(path.read_bytes()) != digest:
        raise SnapshotError(f"missing/corrupt blob for {owner}: {digest}")


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


def _external_target_url(record: dict[str, Any]) -> str:
    provider = record.get("provider")
    status = record.get("status")
    if provider != "mooncakes" or status != "exact":
        raise SnapshotError("external target records must be exact Mooncakes routes")
    module_parts = _segments(record.get("module"), field="module")
    package_parts = _segments(record.get("package"), field="package")
    resolved_version = record.get("resolved_version")
    anchor = record.get("anchor")
    if not isinstance(resolved_version, str) or not resolved_version:
        raise SnapshotError("external target resolved_version must be non-empty")
    if not isinstance(anchor, str) or not anchor:
        raise SnapshotError("external target anchor must be non-empty")
    if package_parts[: len(module_parts)] != module_parts:
        raise SnapshotError("external target package must belong to its module")

    if record["module"] == "moonbitlang/core":
        route_parts = package_parts
    else:
        versioned_module = [
            *module_parts[:-1],
            module_parts[-1] + "@" + resolved_version,
        ]
        route_parts = [*versioned_module, *package_parts[len(module_parts) :]]
    path = "/docs/" + "/".join(_encoded_segment(part) for part in route_parts)
    fragment = quote(anchor, safe=":-._~")
    return f"https://mooncakes.io{path}#{fragment}"


def _validate_external_target(record: dict[str, Any]) -> None:
    _require(
        record,
        {
            "external_target_id",
            "provider",
            "module",
            "resolved_version",
            "package",
            "anchor",
            "url",
            "status",
        },
        "external target",
    )
    target_id = record["external_target_id"]
    if not isinstance(target_id, str) or not target_id:
        raise SnapshotError("external target requires a non-empty external_target_id")
    url = record["url"]
    if not isinstance(url, str):
        raise SnapshotError(f"external target {target_id!r} has a non-string URL")
    try:
        parsed = urlsplit(url)
    except ValueError as exc:
        raise SnapshotError(f"external target {target_id!r} has an invalid URL") from exc
    if (
        parsed.scheme != "https"
        or parsed.netloc != "mooncakes.io"
        or parsed.query
        or not parsed.fragment
    ):
        raise SnapshotError(f"external target {target_id!r} has an unsafe Mooncakes URL")
    expected = _external_target_url(record)
    if url != expected:
        raise SnapshotError(
            f"external target {target_id!r} URL does not match its route fields"
        )


def _validate_definition_external_target(
    definition: dict[str, Any],
    target_source: dict[str, Any],
    external_targets: dict[str, dict[str, Any]],
) -> None:
    external_target_id = definition.get("external_target_id")
    external_status = definition.get("external_status")
    if external_status is not None and (
        not isinstance(external_status, str) or not external_status
    ):
        raise SnapshotError("definition external_status must be a non-empty string")
    if external_target_id is None:
        if external_status == "exact":
            raise SnapshotError("exact external definition is missing external_target_id")
        return
    if not isinstance(external_target_id, str) or not external_target_id:
        raise SnapshotError("definition external_target_id must be a non-empty string")
    if external_status != "exact":
        raise SnapshotError("definition external_target_id requires external_status='exact'")
    if target_source.get("origin") in {"local", "standalone"}:
        raise SnapshotError("local/standalone definition target cannot be external")
    target = external_targets.get(external_target_id)
    if target is None or target.get("status") != "exact":
        raise SnapshotError(f"definition references missing external target: {external_target_id}")


def _validate_range(value: Any, source_id: str, blobs: dict[str, bytes], boundaries: dict[str, set[int]], owner: str) -> None:
    if not isinstance(value, list) or len(value) != 2 or any(not isinstance(item, int) for item in value):
        raise SnapshotError(f"invalid {owner} range for {source_id}: {value!r}")
    start, end = value
    if start < 0 or end < start or end > len(blobs[source_id]) or start not in boundaries[source_id] or end not in boundaries[source_id]:
        raise SnapshotError(f"out-of-bounds/non-UTF-8 {owner} range for {source_id}: {value!r}")
