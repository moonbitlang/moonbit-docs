from __future__ import annotations

import json
from pathlib import Path
import sys


REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.moonbit_semantic.canonical import canonical_json_bytes
from scripts.moonbit_semantic.indexer import BuildConfig, SemanticIndexer
from scripts.moonbit_semantic.runner import CommandResult
from scripts.moonbit_semantic.snapshot import validate_snapshot


class FakeRunner:
    def run(self, args, *, cwd=None, input=None, timeout=None):
        values = tuple(str(value) for value in args)
        if "-dump-tokens" in values:
            tokens = [
                {"token": ["LIDENT", "name"], "loc": "1:4-1:8"}
            ]
            return CommandResult(values, 0, json.dumps(tokens).encode(), b"")
        if values[-2:] == ("version", "--all"):
            return CommandResult(values, 0, b"moon fake\n", b"")
        if values[-1:] == ("--version",):
            return CommandResult(values, 0, b"moon-lsp fake\n", b"")
        if values[-1:] == ("--help",):
            return CommandResult(values, 0, b"mooninfo fake\n", b"")
        return CommandResult(values, 0, b"", b"")


class ExternalDefinitionLsp:
    position_encoding = "utf-16"

    def __init__(self, target: Path):
        self.target = target.resolve()

    def open(self, path: Path, text: str) -> str:
        return Path(path).resolve().as_uri()

    def hover(self, uri, position):
        return {
            "contents": {
                "kind": "markdown",
                "value": "```moonbit\npub fn name() -> Unit\n```",
            },
            "range": {
                "start": {"line": 0, "character": 3},
                "end": {"line": 0, "character": 7},
            },
        }

    def definition(self, uri, position):
        return {
            "uri": self.target.as_uri(),
            "range": {
                "start": {"line": 0, "character": 7},
                "end": {"line": 0, "character": 11},
            },
        }

    def close_document(self, uri):
        return None

    def close(self):
        return None


class FakeMooncakesFetcher:
    def __init__(self, values: dict[str, object]):
        self.values = values
        self.calls: list[str] = []

    def __call__(self, url: str) -> bytes:
        self.calls.append(url)
        if url not in self.values:
            raise OSError(f"unexpected URL: {url}")
        return json.dumps(self.values[url]).encode("utf-8")


def read_jsonl(path: Path) -> list[dict[str, object]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line
    ]


def test_indexer_persists_exact_mooncakes_target_without_live_network(
    tmp_path: Path,
) -> None:
    repo = tmp_path / "repo"
    app = repo / "next/sources/app"
    dependency = app / ".mooncakes/acme/lib"
    stdlib = repo / "toolchain/core"
    for directory in (app, dependency, stdlib):
        directory.mkdir(parents=True)
    (app / "moon.mod.json").write_bytes(
        canonical_json_bytes({"name": "example/app", "version": "1.0.0"})
    )
    local_source = app / "main.mbt"
    local_source.write_text("fn name() -> Unit {}\n", encoding="utf-8")
    (dependency / "moon.mod.json").write_bytes(
        canonical_json_bytes({"name": "acme/lib", "version": "2.1.0"})
    )
    dependency_source = dependency / "lib.mbt"
    dependency_source.write_text("pub fn name() -> Unit {}\n", encoding="utf-8")
    (stdlib / "moon.mod").write_text(
        'name = "moonbitlang/core"\nversion = "test"\n', encoding="utf-8"
    )
    (stdlib / "builtin.mbt").write_text(
        "pub fn builtin() -> Unit {}\n", encoding="utf-8"
    )
    metadata = {
        "source_dir": str(app),
        "name": "example/app",
        "backend": "wasm-gc",
        "packages": [
            {
                "root": "example/app",
                "rel": "",
                "root-path": str(app),
                "files": {str(local_source): {}},
                "mbt-md-files": {},
                "deps": [
                    {"path": "acme/lib", "fspath": str(dependency)}
                ],
                "wbtest-deps": [],
                "test-deps": [],
            }
        ],
    }
    (app / "_build").mkdir()
    (app / "_build/packages.json").write_bytes(canonical_json_bytes(metadata))

    manifest_url = "https://mooncakes.io/api/v0/manifest/acme/lib@2.1.0"
    module_index_url = (
        "https://mooncakes.io/assets/acme/lib@2.1.0/module_index.json"
    )
    package_data_url = (
        "https://mooncakes.io/assets/acme/lib@2.1.0/package_data.json"
    )
    fetcher = FakeMooncakesFetcher({
        manifest_url: {
            "name": "acme/lib",
            "module": "acme/lib",
            "version": "2.1.0",
            "has_package": True,
            "build_status": "success",
        },
        module_index_url: {
            "name": "acme",
            "package": None,
            "childs": [
                {
                    "name": "lib",
                    "package": {
                        "path": "acme/lib",
                        "typealias": [],
                        "traits": [],
                        "errors": [],
                        "types": [],
                        "values": ["name"],
                        "misc": [],
                    },
                    "childs": [],
                }
            ],
        },
        package_data_url: {
            "name": "acme/lib",
            "typealias": [],
            "traits": [],
            "errors": [],
            "types": [],
            "values": [
                {
                    "name": "name",
                    "loc": {
                        "path": "acme/lib",
                        "file": "lib.mbt",
                        "line": 1,
                        "column": 8,
                    },
                }
            ],
            "misc": [],
        },
    })
    output = repo / "semantic-snapshot"
    manifest = SemanticIndexer(BuildConfig(
        repo_root=repo,
        source_root=Path("next/sources"),
        output=output,
        stdlib_root=stdlib,
        runner=FakeRunner(),
        lsp_factory=lambda _root: ExternalDefinitionLsp(dependency_source),
        skip_check=True,
        mooncakes_cache=repo / ".semantic-cache/mooncakes",
        mooncakes_fetcher=fetcher,
        jobs=4,
    )).build()

    validate_snapshot(output)
    assert manifest["analysis"]["external_targets"] == "mooncakes"
    assert manifest["counts"]["external_targets"] == 1
    targets = read_jsonl(output / "external-targets.jsonl")
    assert len(targets) == 1
    target = targets[0]
    assert target["external_target_id"].startswith("mooncakes:")
    assert target["module"] == "acme/lib"
    assert target["requested_version"] == "2.1.0"
    assert target["resolved_version"] == "2.1.0"
    assert target["package"] == "acme/lib"
    assert target["anchor"] == "name"
    assert target["url"] == "https://mooncakes.io/docs/acme/lib@2.1.0#name"

    definitions = [
        definition
        for shard in (output / "occurrences").glob("*/*.json")
        for occurrence in json.loads(shard.read_text())["occurrences"]
        for definition in occurrence.get("definitions", [])
        if definition.get("target_source_id", "").startswith("dependency:")
    ]
    assert definitions
    assert all(
        definition["external_target_id"] == target["external_target_id"]
        and definition["external_status"] == "exact"
        and "_external_evidence" not in definition
        for definition in definitions
    )
    diagnostics = read_jsonl(output / "diagnostics.jsonl")
    provider_diagnostic = next(
        item for item in diagnostics if item["kind"] == "mooncakes-definition"
    )
    assert provider_diagnostic == {
        "kind": "mooncakes-definition",
        "module": "acme/lib",
        "package": "acme/lib",
        "reason": "",
        "root_id": "",
        "source_id": "",
        "status": "exact",
    }
    assert fetcher.calls == [manifest_url, module_index_url, package_data_url]
