from __future__ import annotations

import json
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.moonbit_semantic.canonical import canonical_json_bytes, digest_bytes, digest_json
from scripts.moonbit_semantic.indexer import BuildConfig, SemanticIndexer
from scripts.moonbit_semantic.inventory import Root, discover_roots, metadata_allowed_module_roots, package_metadata, scan_sources
from scripts.moonbit_semantic.literate import extract_literate_fences, moonbit_projection
from scripts.moonbit_semantic.lsp import JsonRpcProcess, LspError, LspSession
from scripts.moonbit_semantic.ranges import RangeError, SourceCoordinates
from scripts.moonbit_semantic.runner import CommandResult
from scripts.moonbit_semantic.snapshot import SnapshotError, validate_snapshot


class FakeRunner:
    def run(self, args, *, cwd=None, input=None, timeout=None):
        args = tuple(str(arg) for arg in args)
        if "-dump-tokens" in args:
            path = Path(args[args.index("-dump-tokens") + 1])
            # One identifier is enough to exercise hover + definition. Locations
            # deliberately use mooninfo's one-based scalar coordinate contract.
            value = [{"token": ["LIDENT", "name"], "loc": "1:4-1:8"}]
            return CommandResult(args, 0, json.dumps(value).encode(), b"")
        if args[-2:] == ("version", "--all"):
            return CommandResult(args, 0, b"moon fake\n", b"")
        if args[-1:] == ("--version",):
            return CommandResult(args, 0, b"lsp fake\n", b"")
        if args[-1:] == ("--help",):
            return CommandResult(args, 0, b"mooninfo fake\n", b"")
        return CommandResult(args, 0, b"", b"")


class FakeLsp:
    position_encoding = "utf-16"

    def __init__(self):
        self.uri = ""

    def open(self, path, text):
        self.uri = Path(path).resolve().as_uri()
        return self.uri

    def hover(self, uri, position):
        return {
            "contents": {"kind": "markdown", "value": "```moonbit\nfn name() -> Unit\n```"},
            "range": {"start": {"line": 0, "character": 3}, "end": {"line": 0, "character": 7}},
        }

    def definition(self, uri, position):
        return {"uri": self.uri, "range": {"start": {"line": 0, "character": 3}, "end": {"line": 0, "character": 7}}}

    def close_document(self, uri):
        pass

    def close(self):
        pass


class SemanticIndexerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        self.sources = self.repo / "next/sources"
        app = self.sources / "app"
        dependency = app / ".mooncakes/acme/lib"
        stdlib = self.repo / "toolchain/core"
        for path in (app, dependency, stdlib):
            path.mkdir(parents=True)
        self._write_json(app / "moon.mod.json", {"name": "example/app", "version": "1.0.0"})
        (app / "main.mbt").write_text("fn name() -> Unit {}\n", encoding="utf-8")
        (app / "guide.mbt.md").write_text("# Guide\n\n```mbt nocheck\ninvalid ???\n```\n\n> ```moonbit check\n> fn prose() {}\n> ```\n", encoding="utf-8")
        (app / "icon.png").write_bytes(b"png")
        global_image = self.repo / "next/imgs/global.png"
        global_image.parent.mkdir(parents=True)
        global_image.write_bytes(b"global-png")
        (app / "guide.mbt.md").write_text(
            (app / "guide.mbt.md").read_text()
            + "\n![icon](./icon.png)\n![global](/imgs/global.png)\n",
            encoding="utf-8",
        )
        self._write_json(dependency / "moon.mod.json", {"name": "acme/lib", "version": "2.1.0", "license": "Apache-2.0"})
        (dependency / "lib.mbt").write_text("fn name() -> Unit {}\n", encoding="utf-8")
        (dependency / "types.mbti").write_text("pub fn name() -> Unit\n", encoding="utf-8")
        (stdlib / "moon.mod").write_text('name = "moonbitlang/core"\nversion = "0.10.2"\nlicense = "Apache-2.0"\n', encoding="utf-8")
        (stdlib / "builtin.mbt").write_text("fn name() -> Unit {}\n", encoding="utf-8")
        package = {
            "source_dir": str(app), "name": "example/app", "backend": "wasm-gc",
            "packages": [{
                "root-path": str(app), "files": {str(app / "main.mbt"): {}},
                "mbt-md-files": {str(app / "guide.mbt.md"): {}},
                "artifact": str(app / "_build/app.mi"),
                "check-command": ["-pkg-sources", f"example/app:{app}"],
                "deps": [
                    {"path": "acme/lib", "fspath": str(dependency)},
                    {"path": "moonbitlang/core", "fspath": str(stdlib)},
                ],
            }],
        }
        self._write_json(app / "_build/packages.json", package)
        self.stdlib = stdlib

    def tearDown(self):
        self.temp.cleanup()

    def test_complete_fake_tool_build_is_deterministic_and_valid(self):
        manifests = []
        outputs = []
        session_roots = []
        checked_roots = []

        class RecordingRunner(FakeRunner):
            def run(inner_self, args, **kwargs):
                values = tuple(str(arg) for arg in args)
                if "check" in values and "-C" in values:
                    checked_roots.append(values[values.index("-C") + 1])
                return super().run(args, **kwargs)

        for name in ("snapshot-a", "nested/snapshot-b"):
            output = self.repo / name

            def factory(root):
                session_roots.append(root.root_id)
                return FakeLsp()

            config = BuildConfig(
                repo_root=self.repo, source_root=Path("next/sources"), output=output,
                stdlib_root=self.stdlib, runner=RecordingRunner(),
                lsp_factory=factory,
            )
            manifests.append(SemanticIndexer(config).build())
            outputs.append(output)
            validate_snapshot(output)
        self.assertEqual(manifests[0]["corpus_digest"], manifests[1]["corpus_digest"])
        self.assertEqual(manifests[0]["counts"], manifests[1]["counts"])
        sources = self._jsonl(outputs[0] / "sources.jsonl")
        origins = {item["origin"] for item in sources}
        self.assertEqual(origins, {"local", "dependency", "stdlib"})
        self.assertFalse(
            any(
                item["origin"] == "local" and ".mooncakes" in Path(item["path"]).parts
                for item in sources
            )
        )
        self.assertFalse(
            any("/.mooncakes/" in root for root in checked_roots)
        )
        self.assertNotIn(str(self.stdlib), checked_roots)
        self.assertTrue(any(item["kind"] == "mbti" and item["analysis_status"] == "display-only" for item in sources))
        dependency_sources = [item for item in sources if item["origin"] == "dependency"]
        self.assertEqual({item["path"] for item in dependency_sources}, {"lib.mbt", "types.mbti"})
        self.assertTrue(
            all(
                item["analysis_status"]
                == ("display-only" if item["kind"] in {"mbti", "mbtp"} else "deferred-by-origin-policy")
                for item in dependency_sources
            )
        )
        self.assertTrue(
            all(
                item["analysis_status"] == "deferred-by-origin-policy"
                for item in sources
                if item["origin"] == "stdlib"
            )
        )
        self.assertFalse(
            any(
                root_id.startswith(("dependency:", "stdlib:"))
                for root_id in session_roots
            )
        )
        contexts = self._jsonl(outputs[0] / "contexts.jsonl")
        by_source = {item["source_id"]: item for item in sources}
        for context in contexts:
            self.assertEqual(context["analysis_origins"], ["local", "standalone"])
            self.assertTrue(
                all(
                    by_source[source_id]["origin"] in {"local", "standalone"}
                    for source_id in context["analysis_source_ids"]
                )
            )
        for shard_root in ("requests", "occurrences"):
            for shard in (outputs[0] / shard_root).glob("*/*.json"):
                source_id = json.loads(shard.read_text())["source_id"]
                self.assertIn(by_source[source_id]["origin"], {"local", "standalone"})
        self.assertEqual(
            manifests[0]["analysis"],
            {
                "origins": ["local", "standalone"],
                "external_targets": "mooncakes",
            },
        )
        self.assertEqual(manifests[0]["counts"]["external_targets"], 0)
        self.assertGreater(manifests[0]["counts"]["symbols"], 0)
        self.assertGreater(manifests[0]["counts"]["hovers"], 0)
        # Literate prose and its images are rendered by the normal Sphinx/MyST
        # document pipeline. The semantic snapshot no longer freezes a second
        # copy solely for removed standalone source pages.
        self.assertEqual(self._jsonl(outputs[0] / "assets.jsonl"), [])
        inputs = self._jsonl(outputs[0] / "analysis-inputs.jsonl")
        for item in inputs:
            blob = outputs[0] / "blobs/sha256" / item["blob_digest"].removeprefix("sha256:")
            self.assertTrue(blob.is_file())
        public_inputs = (outputs[0] / "analysis-inputs.jsonl").read_text()
        self.assertNotIn(str(self.repo), public_inputs)
        self.assertNotIn(str(self.repo.resolve()), public_inputs)

    def test_mixed_target_packages_get_disjoint_analysis_contexts(self):
        module = self.sources / "mixed-target"
        backend = module / "backend/main.mbt"
        frontend = module / "frontend/main.mbt"
        backend.parent.mkdir(parents=True)
        frontend.parent.mkdir(parents=True)
        self._write_json(
            module / "moon.mod.json",
            {
                "name": "example/mixed-target",
                "version": "1.0.0",
                "preferred-target": "native",
                "supported-targets": "+native+js",
            },
        )
        backend.write_text("fn name() -> Unit {}\n", encoding="utf-8")
        frontend.write_text("fn name() -> Unit {}\n", encoding="utf-8")
        (backend.parent / "moon.pkg").write_text(
            'supported_targets = "native"\n', encoding="utf-8"
        )
        (frontend.parent / "moon.pkg").write_text(
            'supported_targets = "js"\n', encoding="utf-8"
        )
        self._write_json(
            module / "_build/packages.json",
            {
                "source_dir": str(module),
                "name": "example/mixed-target",
                "backend": "native",
                "packages": [
                    {
                        "root": "example/mixed-target",
                        "rel": "backend",
                        "root-path": str(backend.parent),
                        "supported-targets": ["Native"],
                        "files": {str(backend): {}},
                    },
                    {
                        "root": "example/mixed-target",
                        "rel": "frontend",
                        "root-path": str(frontend.parent),
                        "supported-targets": ["Js"],
                        "files": {str(frontend): {}},
                    },
                ],
            },
        )
        opened: list[tuple[str, str]] = []
        checked_targets: list[str] = []

        class RecordingRunner(FakeRunner):
            def run(inner_self, args, **kwargs):
                values = tuple(str(value) for value in args)
                if "check" in values and "--target" in values:
                    checked_targets.append(values[values.index("--target") + 1])
                return super().run(args, **kwargs)

        class TargetAwareLsp(FakeLsp):
            def __init__(inner_self, backend_name):
                super().__init__()
                inner_self.backend_name = backend_name
                inner_self.package = ""

            def open(inner_self, path, text):
                inner_self.package = Path(path).parent.name
                opened.append((inner_self.backend_name, inner_self.package))
                return super().open(path, text)

            def _supported(inner_self):
                expected = {"backend": "native", "frontend": "js"}
                return inner_self.backend_name == expected[inner_self.package]

            def hover(inner_self, uri, position):
                return super().hover(uri, position) if inner_self._supported() else None

            def definition(inner_self, uri, position):
                return (
                    super().definition(uri, position)
                    if inner_self._supported()
                    else None
                )

        output = self.repo / "snapshot-mixed-target"
        SemanticIndexer(
            BuildConfig(
                repo_root=self.repo,
                source_root=module,
                output=output,
                stdlib_root=self.stdlib,
                runner=RecordingRunner(),
                lsp_factory=lambda root: TargetAwareLsp(root.backend),
                sessions=1,
            )
        ).build()
        validate_snapshot(output)

        contexts = self._jsonl(output / "contexts.jsonl")
        sources = self._jsonl(output / "sources.jsonl")
        by_path = {item["path"]: item for item in sources}
        backend_source = by_path["next/sources/mixed-target/backend/main.mbt"]
        frontend_source = by_path["next/sources/mixed-target/frontend/main.mbt"]

        def owners(source_id):
            return [
                context
                for context in contexts
                if source_id in context["analysis_source_ids"]
            ]

        backend_owners = owners(backend_source["source_id"])
        frontend_owners = owners(frontend_source["source_id"])
        self.assertEqual(len(backend_owners), 1)
        self.assertEqual(len(frontend_owners), 1)
        self.assertEqual(backend_owners[0]["backend"], "native")
        self.assertEqual(frontend_owners[0]["backend"], "js")
        self.assertEqual(
            backend_source["context_id"], backend_owners[0]["context_id"]
        )
        self.assertEqual(
            frontend_source["context_id"], frontend_owners[0]["context_id"]
        )
        self.assertNotEqual(
            backend_owners[0]["context_id"], frontend_owners[0]["context_id"]
        )
        self.assertIn(("native", "backend"), opened)
        self.assertIn(("js", "frontend"), opened)
        self.assertNotIn(("native", "frontend"), opened)
        self.assertNotIn(("js", "backend"), opened)
        self.assertGreaterEqual(set(checked_targets), {"native", "js"})

        ledgers = [
            json.loads(path.read_text())
            for path in (output / "occurrences").glob("*/*.json")
        ]
        frontend_ledgers = [
            ledger
            for ledger in ledgers
            if ledger["source_id"] == frontend_source["source_id"]
        ]
        self.assertEqual(len(frontend_ledgers), 1)
        self.assertEqual(
            frontend_ledgers[0]["context_id"],
            frontend_source["context_id"],
        )
        self.assertTrue(frontend_ledgers[0]["occurrences"])
        self.assertTrue(
            any(
                occurrence.get("hover_id")
                for occurrence in frontend_ledgers[0]["occurrences"]
            )
        )
        analysis_inputs = self._jsonl(output / "analysis-inputs.jsonl")
        variant_inputs = [
            item
            for item in analysis_inputs
            if item["kind"] == "package-metadata-variant"
        ]
        self.assertEqual(len(variant_inputs), 1)
        self.assertEqual(
            frontend_owners[0]["package_metadata_digest"],
            variant_inputs[0]["blob_digest"],
        )
        public_snapshot = "\n".join(
            path.read_text(encoding="utf-8")
            for path in output.rglob("*.json*")
        )
        self.assertNotIn("moonbit-semantic-targets-", public_snapshot)

        class LeakyAlternateLsp(TargetAwareLsp):
            def definition(inner_self, uri, position):
                if inner_self.backend_name != "js":
                    return super().definition(uri, position)
                return {
                    "uri": "file://blocked" + uri.removeprefix("file://"),
                    "range": {
                        "start": {"line": 0, "character": 3},
                        "end": {"line": 0, "character": 7},
                    },
                }

        partial_output = self.repo / "snapshot-mixed-target-partial"
        SemanticIndexer(
            BuildConfig(
                repo_root=self.repo,
                source_root=module,
                output=partial_output,
                stdlib_root=self.stdlib,
                runner=RecordingRunner(),
                lsp_factory=lambda root: LeakyAlternateLsp(root.backend),
                sessions=1,
                strict=False,
            )
        ).build()
        validate_snapshot(partial_output)
        request_payload = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (partial_output / "requests").glob("*/*.json")
        )
        self.assertIn('"status":"error"', request_payload)
        self.assertNotIn("moonbit-semantic-targets-", request_payload)
        self.assertNotIn(str(self.repo), request_payload)

    def test_workspace_container_and_member_have_disjoint_canonical_contexts(self):
        workspace = self.sources / "workspace-contexts"
        member = workspace / "member"
        container_source = workspace / "main.mbt"
        member_source = member / "main.mbt"
        member.mkdir(parents=True)
        (workspace / "moon.work").write_text(
            'members = ["member"]\n', encoding="utf-8"
        )
        self._write_json(
            workspace / "moon.mod.json",
            {"name": "example/workspace", "preferred-target": "wasm-gc"},
        )
        self._write_json(
            member / "moon.mod.json",
            {"name": "example/member", "preferred-target": "wasm-gc"},
        )
        container_source.write_text("fn name() -> Unit {}\n", encoding="utf-8")
        member_source.write_text("fn name() -> Unit {}\n", encoding="utf-8")
        self._write_json(
            workspace / "_build/packages.json",
            {
                "source_dir": str(workspace),
                "backend": "wasm-gc",
                "packages": [
                    {
                        "root": "example/workspace",
                        "root-path": str(workspace),
                        "files": {str(container_source): {}},
                    },
                    {
                        "root": "example/member",
                        "root-path": str(member),
                        "files": {str(member_source): {}},
                    },
                ],
            },
        )

        output = self.repo / "snapshot-workspace-contexts"
        SemanticIndexer(
            BuildConfig(
                repo_root=self.repo,
                source_root=workspace,
                output=output,
                stdlib_root=self.stdlib,
                runner=FakeRunner(),
                lsp_factory=lambda root: FakeLsp(),
                sessions=1,
            )
        ).build()
        validate_snapshot(output)

        sources = {
            item["path"]: item for item in self._jsonl(output / "sources.jsonl")
        }
        contexts = self._jsonl(output / "contexts.jsonl")
        local_sources = [
            sources["next/sources/workspace-contexts/main.mbt"],
            sources["next/sources/workspace-contexts/member/main.mbt"],
        ]
        for source in local_sources:
            owners = [
                context
                for context in contexts
                if source["source_id"] in context["analysis_source_ids"]
            ]
            self.assertEqual(
                len(owners),
                1,
                f"{source['source_id']} must have one canonical analysis owner",
            )
            self.assertEqual(source.get("context_id"), owners[0]["context_id"])

        occurrence_ledgers = [
            json.loads(path.read_text())
            for path in (output / "occurrences").glob("*/*.json")
        ]
        for source in local_sources:
            canonical_ledgers = [
                ledger
                for ledger in occurrence_ledgers
                if ledger["source_id"] == source["source_id"]
                and ledger["context_id"] == source["context_id"]
            ]
            self.assertEqual(len(canonical_ledgers), 1)

    def test_expected_failure_source_has_no_unbacked_canonical_context(self):
        root = self.sources / "error_codes/1234_error"
        source_path = root / "main.mbt"
        root.mkdir(parents=True)
        self._write_json(root / "moon.mod.json", {"name": "example/error"})
        source_path.write_text("fn name() -> Unit {}\n", encoding="utf-8")
        lsp_roots = []

        class ExpectedFailureRunner(FakeRunner):
            def run(inner_self, args, **kwargs):
                values = tuple(str(value) for value in args)
                if "check" in values and any(
                    value.endswith("/1234_error") for value in values
                ):
                    return CommandResult(
                        values, 1, b"", b"intentional documentation error"
                    )
                return super().run(args, **kwargs)

        output = self.repo / "snapshot-expected-failure"
        SemanticIndexer(
            BuildConfig(
                repo_root=self.repo,
                source_root=self.sources / "error_codes",
                output=output,
                stdlib_root=self.stdlib,
                runner=ExpectedFailureRunner(),
                lsp_factory=lambda context_root: (
                    lsp_roots.append(context_root.root_id) or FakeLsp()
                ),
            )
        ).build()
        validate_snapshot(output)

        source = next(
            item
            for item in self._jsonl(output / "sources.jsonl")
            if item["path"].endswith("/error_codes/1234_error/main.mbt")
        )
        self.assertEqual(source["analysis_status"], "expected-failure")
        self.assertEqual(lsp_roots, [])
        occurrence_ledgers = [
            ledger
            for path in (output / "occurrences").glob("*/*.json")
            if (ledger := json.loads(path.read_text()))["source_id"]
            == source["source_id"]
        ]
        request_ledgers = [
            ledger
            for path in (output / "requests").glob("*/*.json")
            if (ledger := json.loads(path.read_text()))["source_id"]
            == source["source_id"]
        ]

        canonical_context = source.get("context_id")
        if canonical_context is None:
            self.assertEqual(occurrence_ledgers, [])
            self.assertEqual(request_ledgers, [])
        else:
            self.assertEqual(
                [ledger["context_id"] for ledger in occurrence_ledgers],
                [canonical_context],
            )
            self.assertEqual(occurrence_ledgers[0]["occurrences"], [])
            self.assertEqual(
                [ledger["context_id"] for ledger in request_ledgers],
                [canonical_context],
            )
            self.assertEqual(
                {request["status"] for request in request_ledgers[0]["requests"]},
                {"skipped-with-reason"},
            )

    def test_external_navigation_collapses_only_proven_public_aliases(self):
        indexer = SemanticIndexer(
            BuildConfig(
                repo_root=self.repo,
                source_root=self.sources,
                output=self.repo / "unused-snapshot",
                mooncakes_cache=None,
                runner=FakeRunner(),
            )
        )
        indexer.external_targets = {
            "json": {
                "status": "exact",
                "package": "moonbitlang/core/json",
                "url": "https://mooncakes.io/docs/moonbitlang/core/json#Json",
            },
            "prelude": {
                "status": "exact",
                "package": "moonbitlang/core/prelude",
                "url": "https://mooncakes.io/docs/moonbitlang/core/prelude#Json",
            },
            "builtin": {
                "status": "exact",
                "package": "moonbitlang/core/builtin",
                "url": "https://mooncakes.io/docs/moonbitlang/core/builtin#Json",
            },
            "test": {
                "status": "exact",
                "package": "moonbitlang/core/test",
                "url": "https://mooncakes.io/docs/moonbitlang/core/test#inspect",
            },
            "debug": {
                "status": "exact",
                "package": "moonbitlang/core/debug",
                "url": "https://mooncakes.io/docs/moonbitlang/core/debug#inspect",
            },
        }

        def exact(target_id):
            return {
                "external_status": "exact",
                "external_target_id": target_id,
            }

        occurrences = [
            {
                "definitions": [
                    exact("json"),
                    {"external_status": "package-not-indexed"},
                ]
            },
            {
                "definitions": [exact("json"), exact("prelude")],
                "_navigation_aliases": {
                    "json": "moonbitlang/core/json"
                },
                "_navigation_qualifier": "json",
            },
            {
                "definitions": [exact("builtin"), exact("prelude")],
            },
            {
                "definitions": [exact("test"), exact("debug")],
            },
            {
                "definitions": [exact("json"), {"symbol_id": "local"}],
            },
        ]
        indexer.occurrence_shards = {
            ("ctx", "source"): {"occurrences": occurrences}
        }

        indexer._finalize_external_navigation()

        self.assertNotIn("preferred_external_target_id", occurrences[0])
        self.assertEqual(
            occurrences[1]["preferred_external_target_id"], "json"
        )
        self.assertEqual(
            occurrences[2]["preferred_external_target_id"], "prelude"
        )
        self.assertNotIn("preferred_external_target_id", occurrences[3])
        self.assertNotIn("preferred_external_target_id", occurrences[4])
        self.assertTrue(
            all(
                "_navigation_aliases" not in occurrence
                and "_navigation_qualifier" not in occurrence
                for occurrence in occurrences
            )
        )

    def test_full_origin_policy_restores_external_analysis_contexts(self):
        session_roots = []
        output = self.repo / "snapshot-full-origins"

        def factory(root):
            session_roots.append(root.root_id)
            return FakeLsp()

        SemanticIndexer(BuildConfig(
            repo_root=self.repo,
            source_root=Path("next/sources"),
            output=output,
            stdlib_root=self.stdlib,
            runner=FakeRunner(),
            lsp_factory=factory,
            semantic_origins=("local", "standalone", "dependency", "stdlib"),
        )).build()

        validate_snapshot(output)
        self.assertTrue(any(item.startswith("dependency:") for item in session_roots))
        self.assertTrue(any(item.startswith("stdlib:") for item in session_roots))
        contexts = self._jsonl(output / "contexts.jsonl")
        self.assertTrue(
            all(
                context["analysis_source_ids"]
                for context in contexts
                if context["root_id"].startswith(("dependency:", "stdlib:"))
            )
        )

    def test_dependency_check_failure_degrades_own_context_but_keeps_pages(self):
        dependency = self.sources / "app/.mooncakes/acme/lib"

        class DependencyFailureRunner(FakeRunner):
            def run(inner_self, args, **kwargs):
                args = tuple(str(arg) for arg in args)
                if "check" in args and any(value.endswith("/.mooncakes/acme/lib") for value in args):
                    return CommandResult(args, 1, b"", b"auxiliary example is stale")
                return super().run(args, **kwargs)

        output = self.repo / "snapshot"
        SemanticIndexer(BuildConfig(
            repo_root=self.repo, source_root=Path("next/sources"), output=output,
            stdlib_root=self.stdlib, runner=DependencyFailureRunner(), lsp_factory=lambda root: FakeLsp(),
            semantic_origins=("local", "standalone", "dependency", "stdlib"),
        )).build()
        validate_snapshot(output)
        sources = self._jsonl(output / "sources.jsonl")
        self.assertTrue(any(item["origin"] == "dependency" and item["path"] == "lib.mbt" for item in sources))
        contexts = self._jsonl(output / "contexts.jsonl")
        dependency_context = next(item for item in contexts if item["root_id"].startswith("dependency:"))
        self.assertEqual(dependency_context["analysis_status"], "display-only")

    def test_duplicate_dependency_tree_maps_consumer_specific_definition_uri(self):
        canonical = self.sources / "app/.mooncakes/acme/lib"
        consumer = self.sources / "consumer"
        alias = consumer / ".mooncakes/acme/lib"
        alias.mkdir(parents=True)
        self._write_json(consumer / "moon.mod.json", {"name": "example/consumer"})
        (consumer / "main.mbt").write_text("fn name() -> Unit {}\n", encoding="utf-8")
        for source in canonical.iterdir():
            if source.is_file():
                (alias / source.name).write_bytes(source.read_bytes())
        metadata = {
            "packages": [{
                "root-path": str(consumer),
                "files": {str(consumer / "main.mbt"): {}},
                "deps": [{"path": "acme/lib", "fspath": str(alias)}],
            }],
        }
        self._write_json(consumer / "_build/packages.json", metadata)

        class ConsumerLsp(FakeLsp):
            def __init__(inner_self, target):
                super().__init__()
                inner_self.target = target

            def definition(inner_self, uri, position):
                return {
                    "uri": inner_self.target.resolve().as_uri(),
                    "range": {
                        "start": {"line": 0, "character": 3},
                        "end": {"line": 0, "character": 7},
                    },
                }

        output = self.repo / "snapshot-alias"
        manifest = SemanticIndexer(BuildConfig(
            repo_root=self.repo,
            source_root=Path("next/sources"),
            output=output,
            stdlib_root=self.stdlib,
            runner=FakeRunner(),
            lsp_factory=lambda root: (
                ConsumerLsp(alias / "lib.mbt")
                if root.module_name == "example/consumer"
                else FakeLsp()
            ),
        )).build()

        validate_snapshot(output)
        self.assertGreater(manifest["counts"]["symbols"], 0)
        dependency_sources = [
            item for item in self._jsonl(output / "sources.jsonl")
            if item["origin"] == "dependency" and item["path"] == "lib.mbt"
        ]
        self.assertEqual(len(dependency_sources), 1)
        dependency_id = dependency_sources[0]["source_id"]
        definitions = [
            definition
            for shard in (output / "occurrences").glob("*/*.json")
            for occurrence in json.loads(shard.read_text())["occurrences"]
            for definition in occurrence.get("definitions", [])
            if definition["target_source_id"] == dependency_id
        ]
        self.assertTrue(definitions)
        self.assertTrue(all(item.get("symbol_id") for item in definitions))
        ledger_source_ids = {
            json.loads(shard.read_text())["source_id"]
            for root in ("requests", "occurrences")
            for shard in (output / root).glob("*/*.json")
        }
        self.assertNotIn(dependency_id, ledger_source_ids)

    def test_lsp_jobs_run_multiple_requests_with_deterministic_output(self):
        app = self.sources / "app"
        (app / "main.mbt").write_text("fn name() { name() }\n", encoding="utf-8")
        lock = threading.Lock()
        state = {"active": 0, "maximum": 0}

        class TwoCandidateRunner(FakeRunner):
            def run(inner_self, args, **kwargs):
                args = tuple(str(arg) for arg in args)
                if "-dump-tokens" in args:
                    path = Path(args[args.index("-dump-tokens") + 1])
                    if "name() { name" not in path.read_text(encoding="utf-8"):
                        return super().run(args, **kwargs)
                    value = [
                        {"token": ["LIDENT", "name"], "loc": "1:4-1:8"},
                        {"token": ["LIDENT", "name"], "loc": "1:13-1:17"},
                    ]
                    return CommandResult(args, 0, json.dumps(value).encode(), b"")
                return super().run(args, **kwargs)

        class ConcurrentLsp(FakeLsp):
            def hover(inner_self, uri, position):
                with lock:
                    state["active"] += 1
                    state["maximum"] = max(state["maximum"], state["active"])
                try:
                    time.sleep(0.02)
                    return super().hover(uri, position)
                finally:
                    with lock:
                        state["active"] -= 1

        output = self.repo / "snapshot-concurrent"
        SemanticIndexer(BuildConfig(
            repo_root=self.repo,
            source_root=Path("next/sources"),
            output=output,
            stdlib_root=self.stdlib,
            runner=TwoCandidateRunner(),
            lsp_factory=lambda root: ConcurrentLsp(),
            jobs=2,
        )).build()

        validate_snapshot(output)
        self.assertGreaterEqual(state["maximum"], 2)

    def test_virtual_module_definition_uri_resolves_to_canonical_source(self):
        class VirtualDefinitionLsp(FakeLsp):
            def definition(inner_self, uri, position):
                return {
                    "uri": "file:///acme/lib/lib.mbt",
                    "range": {
                        "start": {"line": 0, "character": 3},
                        "end": {"line": 0, "character": 7},
                    },
                }

        output = self.repo / "snapshot-virtual-definition"
        manifest = SemanticIndexer(BuildConfig(
            repo_root=self.repo,
            source_root=Path("next/sources"),
            output=output,
            stdlib_root=self.stdlib,
            runner=FakeRunner(),
            lsp_factory=lambda root: (
                VirtualDefinitionLsp()
                if root.module_name == "example/app"
                else FakeLsp()
            ),
        )).build()

        validate_snapshot(output)
        self.assertGreater(manifest["counts"]["symbols"], 0)
        dependency_id = next(
            item["source_id"]
            for item in self._jsonl(output / "sources.jsonl")
            if item["origin"] == "dependency" and item["path"] == "lib.mbt"
        )
        self.assertTrue(
            any(
                definition["target_source_id"] == dependency_id
                for shard in (output / "occurrences").glob("*/*.json")
                for occurrence in json.loads(shard.read_text())["occurrences"]
                for definition in occurrence.get("definitions", [])
            )
        )

    def test_large_context_combines_multiple_sessions_with_async_requests(self):
        counts = {"app": 0}
        lock = threading.Lock()
        app = self.sources / "app"
        other = app / "other.mbt"
        other.write_text("fn name() -> Unit {}\n", encoding="utf-8")
        metadata_path = app / "_build/packages.json"
        metadata = json.loads(metadata_path.read_text())
        metadata["packages"][0]["files"][str(other)] = {}
        self._write_json(metadata_path, metadata)

        def factory(root):
            if root.module_name == "example/app":
                with lock:
                    counts["app"] += 1
            return FakeLsp()

        output = self.repo / "snapshot-hybrid"
        SemanticIndexer(BuildConfig(
            repo_root=self.repo,
            source_root=Path("next/sources"),
            output=output,
            stdlib_root=self.stdlib,
            runner=FakeRunner(),
            lsp_factory=factory,
            jobs=2,
            sessions=2,
            positions_per_session=1,
        )).build()

        validate_snapshot(output)
        self.assertEqual(counts["app"], 2)

    def test_validator_rejects_self_consistent_manifest_with_missing_required_ledger(self):
        output = self.repo / "snapshot"
        SemanticIndexer(BuildConfig(
            repo_root=self.repo, source_root=Path("next/sources"), output=output,
            stdlib_root=self.stdlib, runner=FakeRunner(), lsp_factory=lambda root: FakeLsp(),
        )).build()
        request = next((output / "requests").glob("*/*.json"))
        count = len(json.loads(request.read_text())["requests"])
        request.unlink()
        manifest = json.loads((output / "manifest.json").read_text())
        manifest["counts"]["requests"] -= count
        self._refresh_manifest(output, manifest)
        with self.assertRaisesRegex(SnapshotError, "missing required ledgers"):
            validate_snapshot(output)

    def test_validator_rejects_tampered_blob(self):
        output = self.repo / "snapshot"
        SemanticIndexer(BuildConfig(
            repo_root=self.repo, source_root=Path("next/sources"), output=output,
            stdlib_root=self.stdlib, runner=FakeRunner(), lsp_factory=lambda root: FakeLsp(),
        )).build()
        blob = next((output / "blobs/sha256").iterdir())
        blob.write_bytes(b"tampered")
        with self.assertRaises(SnapshotError):
            validate_snapshot(output)

    def test_inventory_recognizes_full_dependency_module(self):
        roots = discover_roots(self.sources, "wasm-gc")
        app = next(root for root in roots if root.module_name == "example/app")
        metadata = json.loads((app.path / "_build/packages.json").read_text())
        deps = metadata_allowed_module_roots(metadata, self.stdlib)
        self.assertEqual({path.name for path in deps}, {"lib"})
        self.assertEqual({path.name for path in scan_sources(next(iter(deps)))}, {"lib.mbt", "types.mbti"})

    def test_standalone_literate_root_matches_lsp_native_backend(self):
        loose = self.sources / "loose/README.mbt.md"
        loose.parent.mkdir(parents=True)
        loose.write_text("# Loose\n\n```mbt\nfn main {}\n```\n", encoding="utf-8")

        root = next(
            item
            for item in discover_roots(self.sources, "wasm-gc")
            if item.root_id.startswith("standalone:")
        )

        self.assertEqual(root.backend, "native")

    def test_workspace_member_uses_shared_package_metadata(self):
        workspace = self.sources / "workspace"
        member = workspace / "member"
        member.mkdir(parents=True)
        (workspace / "moon.work").write_text("members = [\"member\"]\n", encoding="utf-8")
        self._write_json(member / "moon.mod.json", {"name": "example/member"})
        metadata = {"packages": [{"root-path": str(member), "files": {}}]}
        self._write_json(workspace / "_build/packages.json", metadata)

        root = Root(member, "root:workspace/member", "required", "example/member", "", "wasm-gc")
        actual, path = package_metadata(root)

        self.assertEqual(actual, metadata)
        self.assertEqual(path, (workspace / "_build/packages.json").resolve())

    def test_source_change_during_check_fails_closed(self):
        app_source = self.sources / "app/main.mbt"

        class MutatingRunner(FakeRunner):
            mutated = False

            def run(inner_self, args, **kwargs):
                if "check" in args and not inner_self.mutated:
                    app_source.write_text("fn changed() -> Unit {}\n", encoding="utf-8")
                    inner_self.mutated = True
                return super().run(args, **kwargs)

        with self.assertRaisesRegex(RuntimeError, "changed across moon check"):
            SemanticIndexer(BuildConfig(
                repo_root=self.repo, source_root=Path("next/sources"), output=self.repo / "snapshot",
                stdlib_root=self.stdlib, runner=MutatingRunner(), lsp_factory=lambda root: FakeLsp(),
            )).build()

    @staticmethod
    def _write_json(path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(canonical_json_bytes(value))

    @staticmethod
    def _jsonl(path):
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]

    @staticmethod
    def _refresh_manifest(output, manifest):
        files = []
        for path in sorted(output.rglob("*")):
            if path.is_file() and path.name != "manifest.json":
                raw = path.read_bytes()
                files.append({"path": path.relative_to(output).as_posix(), "digest": digest_bytes(raw), "size": len(raw)})
        manifest["files"] = files
        manifest["corpus_digest"] = digest_json(files)
        (output / "manifest.json").write_bytes(canonical_json_bytes(manifest))


class RangeAndLiterateTest(unittest.TestCase):
    def test_utf16_utf8_round_trip_and_empty_file(self):
        coordinates = SourceCoordinates("a😀中\n".encode())
        for offset in (0, 1, 5, 8, 9):
            position = coordinates.byte_to_position(offset, "utf-16")
            self.assertEqual(coordinates.position_to_byte(position, "utf-16"), offset)
        empty = SourceCoordinates(b"")
        self.assertEqual(empty.position_to_byte({"line": 0, "character": 0}), 0)
        self.assertEqual(empty.byte_to_position(0), {"line": 0, "character": 0})
        with self.assertRaises(RangeError):
            coordinates.byte_to_position(2)

    def test_literate_full_info_blockquote_and_projection(self):
        raw = b"prose\n\n```mbt nocheck\nbad\n```\n\n> ```moonbit check\n> fn ok() {}\n> ```\n"
        fences = extract_literate_fences(raw)
        self.assertEqual([item["fence_kind"] for item in fences], ["mbt-nocheck", "moonbit-check"])
        self.assertEqual([item["semantic_status"] for item in fences], ["display-only", "analyzed"])
        projected = moonbit_projection(raw, fences)
        self.assertNotIn(b"prose", projected)
        self.assertNotIn(b"bad", projected)
        self.assertIn(b"fn ok", projected)
        self.assertEqual(len(projected), len(raw))

    def test_json_rpc_timeout_is_bounded(self):
        import sys
        transport = JsonRpcProcess([sys.executable, "-c", "import time; time.sleep(2)"], Path.cwd(), timeout=0.02)
        try:
            with self.assertRaises(LspError):
                transport.request("initialize", {})
        finally:
            transport.close()

    def test_json_rpc_reads_body_already_buffered_with_headers(self):
        import sys
        import textwrap

        with tempfile.TemporaryDirectory() as directory:
            server = Path(directory) / "server.py"
            server.write_text(textwrap.dedent("""
                import json, sys, time
                first = sys.stdin.buffer.readline()
                length = int(first.split(b":", 1)[1])
                while sys.stdin.buffer.readline() not in (b"\\r\\n", b"\\n"):
                    pass
                sys.stdin.buffer.read(length)
                body = json.dumps({"jsonrpc": "2.0", "id": 1, "result": {"ok": True}}).encode()
                sys.stdout.buffer.write(b"Content-Length: " + str(len(body)).encode() + b"\\r\\n\\r\\n" + body)
                sys.stdout.buffer.flush()
                time.sleep(1)
            """), encoding="utf-8")
            transport = JsonRpcProcess([sys.executable, str(server)], Path.cwd(), timeout=0.2)
            try:
                self.assertEqual(transport.request("test", {}), {"ok": True})
            finally:
                transport.close()

    def test_json_rpc_multiplexes_out_of_order_responses(self):
        import sys
        import textwrap

        with tempfile.TemporaryDirectory() as directory:
            server = Path(directory) / "server.py"
            server.write_text(textwrap.dedent("""
                import json, sys

                def read():
                    first = sys.stdin.buffer.readline()
                    if not first:
                        return None
                    length = int(first.split(b":", 1)[1])
                    while sys.stdin.buffer.readline() not in (b"\\r\\n", b"\\n"):
                        pass
                    return json.loads(sys.stdin.buffer.read(length))

                def send(value):
                    body = json.dumps(value).encode()
                    sys.stdout.buffer.write(
                        b"Content-Length: " + str(len(body)).encode() + b"\\r\\n\\r\\n" + body
                    )
                    sys.stdout.buffer.flush()

                first, second = read(), read()
                send({"jsonrpc": "2.0", "id": second["id"], "result": "second"})
                send({"jsonrpc": "2.0", "id": first["id"], "result": "first"})
                shutdown = read()
                send({"jsonrpc": "2.0", "id": shutdown["id"], "result": None})
                read()
            """), encoding="utf-8")
            transport = JsonRpcProcess(
                [sys.executable, str(server)],
                Path.cwd(),
                timeout=1,
            )
            try:
                _first_id, first = transport.request_async("first", {})
                _second_id, second = transport.request_async("second", {})
                self.assertEqual(second.result(timeout=1), "second")
                self.assertEqual(first.result(timeout=1), "first")
            finally:
                transport.close()

    def test_semantic_batch_reuses_hover_by_verified_definition(self):
        from concurrent.futures import Future

        class ImmediateTransport:
            timeout = 1.0

            def __init__(inner_self):
                inner_self.counts = {"textDocument/definition": 0, "textDocument/hover": 0}

            def request(inner_self, method, params):
                if method == "initialize":
                    return {"capabilities": {"positionEncoding": "utf-16"}}
                return None

            def request_async(inner_self, method, params):
                inner_self.counts[method] += 1
                future = Future()
                if method == "textDocument/definition":
                    value = {
                        "uri": "file:///module/src/top.mbt",
                        "range": {
                            "start": {"line": 0, "character": 3},
                            "end": {"line": 0, "character": 7},
                        },
                    }
                else:
                    value = {
                        "contents": {"kind": "markdown", "value": "fn name()"},
                        "range": {
                            "start": params["position"],
                            "end": params["position"],
                        },
                    }
                future.set_result(value)
                return inner_self.counts[method], future

            def notify(inner_self, method, params):
                return None

            def close(inner_self):
                return None

        transport = ImmediateTransport()
        session = LspSession(transport, Path.cwd())
        positions = [{"line": 0, "character": index} for index in range(10)]

        results = session.hover_definitions("file:///module/src/use.mbt", positions, window=4)

        self.assertEqual(transport.counts["textDocument/definition"], 10)
        self.assertEqual(transport.counts["textDocument/hover"], 1)
        self.assertEqual([result[2] for result in results].count("requested"), 1)
        self.assertEqual([result[2] for result in results].count("reused-definition"), 9)
        self.assertNotIn("range", results[1][0])


if __name__ == "__main__":
    unittest.main()
