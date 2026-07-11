from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

import pytest


ROOT = Path(__file__).resolve().parents[2]
EXT = ROOT / "next" / "_ext"
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
if str(EXT) not in sys.path:
    sys.path.insert(0, str(EXT))

from moonbit_semantic.snapshot import (  # noqa: E402
    DefinitionTarget,
    ExternalTarget,
    SnapshotError as RuntimeSnapshotError,
    Source,
    _external_target,
    _validate_definition_external_target as validate_runtime_definition,
    load_snapshot,
)
from scripts.moonbit_semantic.canonical import digest_json  # noqa: E402
from scripts.moonbit_semantic.snapshot import (  # noqa: E402
    SnapshotError as WriterSnapshotError,
    SnapshotWriter,
    _validate_definition_external_target as validate_writer_definition,
    _validate_external_target as validate_writer_target,
    validate_snapshot,
)


def _external_record(*, core: bool = False) -> dict[str, str]:
    if core:
        return {
            "external_target_id": "mooncakes:core-maximum",
            "provider": "mooncakes",
            "module": "moonbitlang/core",
            "requested_version": "0.10.2+1bb3e16cf",
            "resolved_version": "0.1.20260622+a46be2066",
            "package": "moonbitlang/core/cmp",
            "anchor": "maximum",
            "url": "https://mooncakes.io/docs/moonbitlang/core/cmp#maximum",
            "match": "location",
            "status": "exact",
        }
    return {
        "external_target_id": "mooncakes:async-send-response",
        "provider": "mooncakes",
        "module": "moonbitlang/async",
        "requested_version": "0.19.2",
        "resolved_version": "0.19.2",
        "package": "moonbitlang/async/http",
        "anchor": "ServerConnection::send_response",
        "url": "https://mooncakes.io/docs/moonbitlang/async@0.19.2/http#ServerConnection::send_response",
        "match": "location",
        "status": "exact",
    }


@pytest.mark.parametrize("core", [False, True])
def test_exact_mooncakes_routes_load_in_writer_and_runtime(core: bool) -> None:
    record = _external_record(core=core)

    validate_writer_target(record)
    target = _external_target(record)

    assert isinstance(target, ExternalTarget)
    assert target.external_target_id == record["external_target_id"]
    assert target.url == record["url"]


@pytest.mark.parametrize(
    "url",
    [
        "http://mooncakes.io/docs/moonbitlang/async@0.19.2/http#ServerConnection::send_response",
        "https://example.com/docs/moonbitlang/async@0.19.2/http#ServerConnection::send_response",
        "https://user@mooncakes.io/docs/moonbitlang/async@0.19.2/http#ServerConnection::send_response",
        "https://mooncakes.io:443/docs/moonbitlang/async@0.19.2/http#ServerConnection::send_response",
        "https://mooncakes.io/docs/moonbitlang/async@0.19.2/http?view=api#ServerConnection::send_response",
        "https://mooncakes.io/docs/moonbitlang/async@0.19.2/http",
        "https://mooncakes.io/docs/moonbitlang/async/http#ServerConnection::send_response",
        "https://mooncakes.io/docs/moonbitlang/async@0.19.2/http#send_response",
    ],
)
def test_external_target_rejects_unsafe_or_noncanonical_url(url: str) -> None:
    record = {**_external_record(), "url": url}

    with pytest.raises(WriterSnapshotError):
        validate_writer_target(record)
    with pytest.raises(RuntimeSnapshotError):
        _external_target(record)


def test_definition_reference_requires_exact_existing_external_target() -> None:
    record = _external_record()
    target = _external_target(record)
    dependency_source = {
        "source_id": "dependency:moonbitlang/async@0.19.2:http/server.mbt",
        "origin": "dependency",
        "module": "moonbitlang/async",
        "version": "0.19.2",
    }
    runtime_source = Source(
        source_id=dependency_source["source_id"],
        path="http/server.mbt",
        blob_digest="sha256:unused",
        kind="mbt",
        origin="dependency",
        module="moonbitlang/async",
        version="0.19.2",
    )
    definition_record = {
        "external_target_id": record["external_target_id"],
        "external_status": "exact",
    }
    definition = DefinitionTarget(
        source_id=runtime_source.source_id,
        selection_range=(0, 1),
        external_target_id=record["external_target_id"],
        external_status="exact",
    )

    validate_writer_definition(
        definition_record,
        dependency_source,
        {record["external_target_id"]: record},
    )
    validate_runtime_definition(
        definition,
        runtime_source,
        {target.external_target_id: target},
    )
    validate_writer_definition(
        {"external_status": "unsupported"}, dependency_source, {}
    )
    validate_runtime_definition(
        DefinitionTarget(
            source_id=runtime_source.source_id,
            selection_range=(0, 1),
            external_status="unsupported",
        ),
        runtime_source,
        {},
    )

    with pytest.raises(WriterSnapshotError, match="missing external target"):
        validate_writer_definition(definition_record, dependency_source, {})
    with pytest.raises(RuntimeSnapshotError, match="missing external target"):
        validate_runtime_definition(definition, runtime_source, {})

    with pytest.raises(WriterSnapshotError, match="missing external_target_id"):
        validate_writer_definition(
            {"external_status": "exact"}, dependency_source, {}
        )
    with pytest.raises(RuntimeSnapshotError, match="missing external_target_id"):
        validate_runtime_definition(
            DefinitionTarget(
                source_id=runtime_source.source_id,
                selection_range=(0, 1),
                external_status="exact",
            ),
            runtime_source,
            {},
        )

    local_source = {**dependency_source, "origin": "local"}
    with pytest.raises(WriterSnapshotError, match="local/standalone"):
        validate_writer_definition(
            definition_record,
            local_source,
            {record["external_target_id"]: record},
        )
    with pytest.raises(RuntimeSnapshotError, match="local/standalone"):
        validate_runtime_definition(
            definition,
            Source(
                source_id=runtime_source.source_id,
                path=runtime_source.path,
                blob_digest=runtime_source.blob_digest,
                kind=runtime_source.kind,
                origin="standalone",
            ),
            {target.external_target_id: target},
        )

    for field, wrong in (
        ("module", "moonbitlang/other"),
        ("version", "9.9.9"),
    ):
        with pytest.raises(WriterSnapshotError, match="does not match"):
            validate_writer_definition(
                definition_record,
                {**dependency_source, field: wrong},
                {record["external_target_id"]: record},
            )
        with pytest.raises(RuntimeSnapshotError, match="does not match"):
            validate_runtime_definition(
                definition,
                Source(
                    source_id=runtime_source.source_id,
                    path=runtime_source.path,
                    blob_digest=runtime_source.blob_digest,
                    kind=runtime_source.kind,
                    origin=runtime_source.origin,
                    module=(
                        wrong if field == "module" else runtime_source.module
                    ),
                    version=(
                        wrong if field == "version" else runtime_source.version
                    ),
                ),
                {target.external_target_id: target},
            )


def _publish_writer_snapshot(
    root: Path,
    external_targets: list[dict[str, str]] | None,
) -> Path:
    output = root / "writer-snapshot"
    writer = SnapshotWriter(output)
    raw = b"pub fn maximum() -> Int { 42 }\n"
    blob_digest = writer.write_blob(raw)
    writer.write_table(
        "sources.jsonl",
        [
            {
                "source_id": "dependency:moonbitlang/core@toolchain:cmp/cmp.mbt",
                "origin": "dependency",
                "path": "cmp/cmp.mbt",
                "kind": "mbt",
                "blob_digest": blob_digest,
                "analysis_status": "deferred-by-origin-policy",
                "route_key": "unused",
            }
        ],
        ("source_id",),
    )
    for table, fields in (
        ("analysis-inputs.jsonl", ("root_id", "path")),
        ("assets.jsonl", ("asset_id",)),
        ("contexts.jsonl", ("context_id",)),
        ("symbols.jsonl", ("symbol_id",)),
        ("diagnostics.jsonl", ("root_id", "kind")),
    ):
        writer.write_table(table, [], fields)
    if external_targets is not None:
        writer.write_table(
            "external-targets.jsonl",
            external_targets,
            ("external_target_id",),
        )
    resolution: dict[str, object] = {"schema": "moonbit-resolution-lock/v1", "modules": []}
    writer.write_shard("resolution-lock.json", resolution)
    counts = {
        "sources": 1,
        "contexts": 0,
        "symbols": 0,
        "assets": 0,
        "hovers": 0,
        "occurrences": 0,
        "requests": 0,
    }
    if external_targets is not None:
        counts["external_targets"] = len(external_targets)
    writer.publish(
        {
            "analyzer": "test",
            "backend": "wasm-gc",
            "toolchain": {},
            "resolution_digest": digest_json(resolution),
            "counts": counts,
        }
    )
    return output


def test_writer_accepts_optional_external_target_table(tmp_path: Path) -> None:
    old_snapshot = _publish_writer_snapshot(tmp_path / "old", None)
    new_snapshot = _publish_writer_snapshot(
        tmp_path / "new", [_external_record(core=True)]
    )

    assert "external_targets" not in validate_snapshot(old_snapshot)["counts"]
    assert validate_snapshot(new_snapshot)["counts"]["external_targets"] == 1


def test_core_external_target_rejects_versioned_docs_url() -> None:
    record = _external_record(core=True)
    record["url"] = (
        "https://mooncakes.io/docs/"
        "moonbitlang/core@0.1.20260622+a46be2066/cmp#maximum"
    )

    with pytest.raises(WriterSnapshotError):
        validate_writer_target(record)
    with pytest.raises(RuntimeSnapshotError):
        _external_target(record)


def _write_runtime_snapshot(
    root: Path,
    *,
    include_external_table: bool,
    include_external_reference: bool,
) -> Path:
    snapshot = root / "runtime-snapshot"
    blobs = snapshot / "blobs" / "sha256"
    occurrences = snapshot / "occurrences"
    blobs.mkdir(parents=True)
    occurrences.mkdir()
    local = b"fn use() { maximum() }\n"
    dependency = b"pub fn maximum() -> Int { 42 }\n"
    local_digest = hashlib.sha256(local).hexdigest()
    dependency_digest = hashlib.sha256(dependency).hexdigest()
    (blobs / local_digest).write_bytes(local)
    (blobs / dependency_digest).write_bytes(dependency)
    sources = [
        {
            "source_id": "local:main.mbt",
            "path": "main.mbt",
            "blob_digest": f"sha256:{local_digest}",
            "kind": "mbt",
            "origin": "local",
        },
        {
            "source_id": "dependency:moonbitlang/core@toolchain:cmp/cmp.mbt",
            "path": "cmp/cmp.mbt",
            "blob_digest": f"sha256:{dependency_digest}",
            "kind": "mbt",
            "origin": "dependency",
        },
    ]
    (snapshot / "sources.jsonl").write_text(
        "".join(json.dumps(source) + "\n" for source in sources),
        encoding="utf-8",
    )
    maximum = local.index(b"maximum")
    dependency_maximum = dependency.index(b"maximum")
    definition: dict[str, object] = {
        "target_source_id": sources[1]["source_id"],
        "target_selection_range_utf8": [dependency_maximum, dependency_maximum + 7],
    }
    if include_external_reference:
        definition.update(
            {
                "external_target_id": _external_record(core=True)["external_target_id"],
                "external_status": "exact",
            }
        )
    (occurrences / "all.json").write_text(
        json.dumps(
            {
                "occurrences": [
                    {
                        "source_id": sources[0]["source_id"],
                        "effective_range_utf8": [maximum, maximum + 7],
                        "definitions": [definition],
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    if include_external_table:
        (snapshot / "external-targets.jsonl").write_text(
            json.dumps(_external_record(core=True)) + "\n",
            encoding="utf-8",
        )
    files = []
    for path in sorted(snapshot.rglob("*")):
        if path.is_file() and path.name != "manifest.json":
            raw = path.read_bytes()
            files.append(
                {
                    "path": path.relative_to(snapshot).as_posix(),
                    "digest": "sha256:" + hashlib.sha256(raw).hexdigest(),
                    "size": len(raw),
                }
            )
    (snapshot / "manifest.json").write_text(
        json.dumps(
            {
                "schema": "moonbit-semantic-snapshot/v1",
                "corpus_digest": "sha256:test",
                "files": files,
            }
        ),
        encoding="utf-8",
    )
    return snapshot


def test_runtime_loader_is_backward_compatible_without_external_table(
    tmp_path: Path,
) -> None:
    snapshot = load_snapshot(
        _write_runtime_snapshot(
            tmp_path,
            include_external_table=False,
            include_external_reference=False,
        )
    )

    assert snapshot.external_targets == {}
    assert snapshot.occurrences["local:main.mbt"][0].definitions[0].external_target_id is None


def test_runtime_loader_resolves_external_target_reference(tmp_path: Path) -> None:
    snapshot = load_snapshot(
        _write_runtime_snapshot(
            tmp_path,
            include_external_table=True,
            include_external_reference=True,
        )
    )

    target_id = _external_record(core=True)["external_target_id"]
    assert snapshot.external_targets[target_id].anchor == "maximum"
    assert (
        snapshot.occurrences["local:main.mbt"][0]
        .definitions[0]
        .external_target_id
        == target_id
    )


def test_runtime_loader_rejects_dangling_external_target_reference(
    tmp_path: Path,
) -> None:
    path = _write_runtime_snapshot(
        tmp_path,
        include_external_table=False,
        include_external_reference=True,
    )

    with pytest.raises(RuntimeSnapshotError, match="missing external target"):
        load_snapshot(path)
