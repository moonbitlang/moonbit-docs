"""End-to-end MoonBit semantic snapshot orchestration."""

from __future__ import annotations

import json
import os
import re
import shutil
import sys
import tempfile
import threading
import time
import unicodedata
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable
from urllib.parse import unquote, urlparse

from .canonical import digest_bytes, digest_json, is_within, normalize_relative, realpath
from .inventory import (
    PackageOwnership, Root, discover_roots, make_source,
    metadata_allowed_module_roots, metadata_package_ownership, metadata_sources,
    metadata_source_backends, module_info, nearest_workspace, package_metadata, recognized,
    scan_sources,
)
from .literate import moonbit_projection
from .lsp import JsonRpcProcess, LspError, LspSession, definition_locations, normalize_hover_contents
from .mooncakes import DefinitionEvidence, Fetcher, MooncakesClient, MooncakesResolution
from .ranges import RangeError, SourceCoordinates
from .runner import CommandError, Runner, SubprocessRunner
from .snapshot import SnapshotWriter

ANALYZER_VERSION = "moonbit-semantic-indexer/2"
LOC = re.compile(r"^(\d+):(\d+)-(\d+):(\d+)$")
IDENTIFIER_TOKENS = {
    "LIDENT", "UIDENT", "DOT_LIDENT", "DOT_UIDENT", "PACKAGE_NAME",
    "LABEL", "QUESTION_LABEL", "POST_LABEL",
}


@dataclass
class BuildConfig:
    repo_root: Path
    source_root: Path
    output: Path
    stdlib_root: Path | None = None
    backend: str = "wasm-gc"
    moon: str = "moon"
    mooninfo: str = "mooninfo"
    moon_lsp: str = "moon-lsp"
    jobs: int = field(
        default_factory=lambda: max(8, min(64, (os.cpu_count() or 1) * 8))
    )
    sessions: int = field(default_factory=lambda: max(1, min(8, os.cpu_count() or 1)))
    positions_per_session: int = 256
    semantic_origins: tuple[str, ...] = ("local", "standalone")
    progress: bool = False
    skip_check: bool = False
    skip_lsp: bool = False
    strict: bool = True
    timeout: float = 120.0
    mooncakes_cache: Path | None = None
    mooncakes_offline: bool = False
    mooncakes_refresh: bool = False
    mooncakes_fetcher: Fetcher | None = None
    runner: Runner = field(default_factory=SubprocessRunner)
    lsp_factory: Callable[[Root], LspSession] | None = None

    def __post_init__(self) -> None:
        self.repo_root = self.repo_root.resolve()
        self.source_root = (self.repo_root / self.source_root).resolve() if not self.source_root.is_absolute() else self.source_root.resolve()
        self.output = (self.repo_root / self.output).resolve() if not self.output.is_absolute() else self.output.resolve()
        if self.stdlib_root is not None:
            self.stdlib_root = self.stdlib_root.resolve()
        if self.mooncakes_cache is not None:
            self.mooncakes_cache = (
                self.repo_root / self.mooncakes_cache
                if not self.mooncakes_cache.is_absolute()
                else self.mooncakes_cache
            ).resolve()
        if self.jobs < 1:
            raise ValueError("jobs must be at least 1")
        if self.sessions < 1:
            raise ValueError("sessions must be at least 1")
        if self.positions_per_session < 1:
            raise ValueError("positions_per_session must be at least 1")
        if self.mooncakes_offline and self.mooncakes_refresh:
            raise ValueError(
                "mooncakes_offline and mooncakes_refresh are mutually exclusive"
            )
        allowed_origins = {"local", "standalone", "dependency", "stdlib"}
        self.semantic_origins = tuple(dict.fromkeys(self.semantic_origins))
        unknown_origins = set(self.semantic_origins) - allowed_origins
        if unknown_origins:
            raise ValueError(
                f"unsupported semantic origins: {sorted(unknown_origins)}"
            )


class SemanticIndexer:
    def __init__(self, config: BuildConfig):
        self.config = config
        self.diagnostics: list[dict[str, Any]] = []
        self.analysis_inputs: list[dict[str, Any]] = []
        self.assets: list[dict[str, Any]] = []
        self.hovers: dict[str, dict[str, str]] = {}
        self.symbols: dict[str, dict[str, Any]] = {}
        self.external_targets: dict[str, dict[str, Any]] = {}
        self.occurrence_shards: dict[tuple[str, str], dict[str, Any]] = {}
        self.request_shards: dict[tuple[str, str], dict[str, Any]] = {}
        self.toolchain: dict[str, Any] = {}
        self.portable_roots: dict[Path, str] = {config.repo_root: "$REPO"}
        self._semantic_lock = threading.Lock()
        self._progress_lock = threading.Lock()
        self._started_at = time.monotonic()
        self._mooncakes = (
            MooncakesClient(
                config.mooncakes_cache,
                offline=config.mooncakes_offline,
                refresh=config.mooncakes_refresh,
                fetcher=config.mooncakes_fetcher,
            )
            if config.mooncakes_cache is not None
            else None
        )

    def build(self) -> dict[str, Any]:
        cfg = self.config
        roots = discover_roots(cfg.source_root, cfg.backend)
        if not roots:
            raise RuntimeError(f"no MoonBit roots found below {cfg.source_root}")
        self._progress(f"discovered {len(roots)} local/standalone roots")
        precheck_sources = {
            root.root_id: {path: path.read_bytes() for path in scan_sources(root.path)}
            for root in roots
        }
        stdlib = cfg.stdlib_root or self._find_stdlib()
        cfg.stdlib_root = stdlib
        if stdlib:
            self.portable_roots[realpath(stdlib)] = "$STDLIB"
        self.toolchain = self._toolchain()
        root_states: dict[str, tuple[Root, dict[str, Any] | None]] = {}
        dependency_roots: set[Path] = set()

        for root_index, root in enumerate(roots, 1):
            if root_index == 1 or root_index % 25 == 0 or root_index == len(roots):
                self._progress(f"checking local roots {root_index}/{len(roots)}")
            check_ok = self._check_barrier(root)
            metadata, metadata_path = package_metadata(root)
            resolved_dependencies = metadata_allowed_module_roots(metadata, stdlib) if metadata else set()
            for dependency in resolved_dependencies:
                self._register_portable_root(dependency)
            if metadata_path and metadata_path.is_file():
                self._input(metadata_path, "package-metadata", root.root_id)
            if root.status == "required" and check_ok and metadata is None and not cfg.skip_check:
                raise RuntimeError(f"moon check produced no package metadata for {root.path}")
            root_states[root.root_id] = (root, metadata)
            dependency_roots.update(resolved_dependencies)
        self._progress(
            f"local check barrier complete; discovered {len(dependency_roots)} resolved dependency roots"
        )

        # Resolved registry/path dependencies are entire modules, never just files hit by LSP.
        dependency_states: list[tuple[Root, dict[str, Any] | None]] = []
        pending = list(sorted(dependency_roots))
        resolved_modules: dict[str, str] = {}
        resolved_module_roots: dict[str, Path] = {}
        dependency_alias_roots: list[tuple[Path, Path]] = []
        while pending:
            path = pending.pop(0)
            info = module_info(path)
            source_tree = _source_tree_digest(path)
            version = info["version"] or source_tree.removeprefix("sha256:")[:16]
            identity = f"{info['name']}@{version}"
            previous = resolved_modules.get(identity)
            if previous is not None:
                if previous != source_tree:
                    raise RuntimeError(f"resolution conflict: {identity} has multiple source trees")
                canonical_root = resolved_module_roots[identity]
                if realpath(path) != canonical_root:
                    dependency_alias_roots.append((realpath(path), canonical_root))
                continue
            resolved_modules[identity] = source_tree
            resolved_module_roots[identity] = realpath(path)
            # A resolved module's captured evidence corpus includes auxiliary
            # examples and nested modules which need not be healthy under the
            # consumer's toolchain. Try its own context, but degrade that context
            # instead of losing definition evidence when one example does not check.
            candidate = Root(path, f"dependency:{identity}", "display-only", info["name"], version, info["preferred_target"] or cfg.backend)
            precheck_sources[candidate.root_id] = {source: source.read_bytes() for source in scan_sources(candidate.path)}
            if "dependency" in cfg.semantic_origins:
                check_ok = self._check_barrier(candidate)
            else:
                check_ok = False
                self._record_policy_skip(candidate, "dependency")
            dep_status = (
                "required"
                if check_ok
                else "display-only"
                if "dependency" in cfg.semantic_origins
                else "deferred-by-origin-policy"
            )
            dep = Root(path, candidate.root_id, dep_status, info["name"], version, candidate.backend)
            metadata, metadata_path = package_metadata(dep)
            resolved_dependencies = metadata_allowed_module_roots(metadata, stdlib) if metadata else set()
            for dependency in resolved_dependencies:
                self._register_portable_root(dependency)
            if metadata_path and metadata_path.is_file():
                self._input(metadata_path, "package-metadata", dep.root_id)
            dependency_states.append((dep, metadata))
            for transitive in sorted(resolved_dependencies):
                if transitive not in pending:
                    pending.append(transitive)
        self._progress(
            f"froze {len(dependency_states)} dependency modules without external occurrence analysis"
        )

        stdlib_state: tuple[Root, dict[str, Any] | None] | None = None
        if stdlib:
            info = module_info(stdlib)
            version = info["version"] or _source_tree_digest(stdlib).removeprefix("sha256:")[:16]
            stdroot = Root(
                stdlib,
                f"stdlib:{info['name']}@{version}",
                "required"
                if "stdlib" in cfg.semantic_origins
                else "deferred-by-origin-policy",
                info["name"],
                version,
                info["preferred_target"] or cfg.backend,
            )
            # The shipped stdlib already contains a pinned bundle. Check when requested, then
            # verify its source and executable digests as analysis inputs either way.
            precheck_sources[stdroot.root_id] = {source: source.read_bytes() for source in scan_sources(stdroot.path)}
            if "stdlib" in cfg.semantic_origins:
                self._check_barrier(stdroot)
            else:
                self._record_policy_skip(stdroot, "stdlib")
            metadata, metadata_path = package_metadata(stdroot)
            if metadata_path and metadata_path.is_file():
                self._input(metadata_path, "package-metadata", stdroot.root_id)
            stdlib_state = (stdroot, metadata)
            self._progress("froze pinned stdlib source corpus")

        sources: dict[str, dict[str, Any]] = {}
        path_to_source: dict[Path, dict[str, Any]] = {}
        for root, metadata in root_states.values():
            self._verify_precheck(root, precheck_sources[root.root_id])
            candidates = set(scan_sources(root.path))
            if metadata:
                # packages.json contains the complete IDE graph, including
                # registry/path dependencies and stdlib sources.  Do not let
                # a consumer claim those files as local merely because its
                # .mooncakes directory lives below the module root.
                candidates.update(
                    path
                    for path in metadata_sources(metadata)
                    if not any(is_within(path, dependency) for dependency in dependency_roots)
                    and not (stdlib and is_within(path, stdlib))
                )
            for path in sorted(candidates):
                origin = "standalone" if root.root_id.startswith("standalone:") else "local"
                source = make_source(path, origin=origin, base=cfg.repo_root, module=root.module_name, version=root.version, status=root.status)
                self._add_source(source, sources, path_to_source)
            self._manifest_inputs(root)

        for root, metadata in dependency_states:
            self._verify_precheck(root, precheck_sources[root.root_id])
            for path in scan_sources(root.path):
                # Analysis completeness belongs to a context.  A dependency's
                # own module-wide check may degrade while its packages remain
                # fully analyzable in a healthy consumer context.
                source = make_source(path, origin="dependency", base=root.path, module=root.module_name, version=root.version, status=root.status)
                self._add_source(source, sources, path_to_source)
            self._manifest_inputs(root)

        # Different consumer roots commonly materialize the same immutable
        # registry module under different `.mooncakes` paths.  Its public page
        # corpus is deduplicated by module identity/tree digest, but LSP
        # Definition responses retain the consumer-specific physical URI.
        # Map every byte-identical alias path back to the canonical source so
        # those targets remain inside the frozen corpus.
        for alias_root, canonical_root in dependency_alias_roots:
            for alias_path in scan_sources(alias_root):
                relative = alias_path.relative_to(alias_root)
                canonical_path = realpath(canonical_root / relative)
                source = path_to_source.get(canonical_path)
                if source is None:
                    raise RuntimeError(
                        f"dependency alias has no canonical source: {alias_path}"
                    )
                if alias_path.read_bytes() != source["_blob"]:
                    raise RuntimeError(
                        f"dependency alias differs from canonical source: {alias_path}"
                    )
                path_to_source[realpath(alias_path)] = source

        if stdlib_state:
            root, _ = stdlib_state
            self._verify_precheck(root, precheck_sources[root.root_id])
            for path in scan_sources(root.path):
                source = make_source(path, origin="stdlib", base=root.path, module=root.module_name, version=root.version, status=root.status)
                self._add_source(source, sources, path_to_source)
            self._manifest_inputs(root)

        logical_sources = _logical_source_map(sources.values())
        canonical_local_sources = self._canonical_local_source_ids(
            root_states, path_to_source
        )

        contexts: list[dict[str, Any]] = []
        active_contexts: list[
            tuple[
                Root,
                dict[str, Any],
                list[dict[str, Any]],
                PackageOwnership,
                dict[Path, dict[str, Any]],
            ]
        ] = []
        all_states = list(root_states.values()) + dependency_states + ([stdlib_state] if stdlib_state else [])
        analysis_workspace = tempfile.TemporaryDirectory(
            prefix="moonbit-semantic-targets-"
        )
        try:
            workspace = Path(analysis_workspace.name)
            for root, metadata in all_states:
                for (
                    variant_root,
                    variant_metadata,
                    variant_path_map,
                    allowed_source_ids,
                    physical_paths,
                    package_metadata_digest,
                ) in self._context_variants(
                    root,
                    metadata,
                    path_to_source,
                    workspace,
                    (
                        canonical_local_sources.get(root.root_id, set())
                        if root.root_id in root_states
                        else None
                    ),
                ):
                    input_sources = self._context_sources(
                        variant_root,
                        variant_metadata,
                        variant_path_map,
                    )
                    if not input_sources:
                        continue
                    analysis_sources = self._analysis_sources(
                        variant_root, input_sources
                    )
                    if allowed_source_ids is not None:
                        analysis_sources = [
                            source
                            for source in analysis_sources
                            if source["source_id"] in allowed_source_ids
                        ]
                    analysis_sources = [
                        {
                            **source,
                            "_realpath": physical_paths.get(
                                source["source_id"], source["_realpath"]
                            ),
                        }
                        for source in analysis_sources
                    ]
                    context = self._context(
                        variant_root,
                        input_sources,
                        analysis_sources,
                        package_metadata_digest,
                    )
                    contexts.append(context)
                    if variant_root.status == "required" and analysis_sources:
                        for source in analysis_sources:
                            canonical = sources[source["source_id"]]
                            previous = canonical.get("context_id")
                            if (
                                previous is not None
                                and previous != context["context_id"]
                            ):
                                raise RuntimeError(
                                    "source assigned to multiple semantic contexts: "
                                    f"{source['source_id']}"
                                )
                            canonical["context_id"] = context["context_id"]
                        ownership = (
                            metadata_package_ownership(variant_metadata)
                            if variant_metadata is not None
                            else PackageOwnership()
                        )
                        active_contexts.append(
                            (
                                variant_root,
                                context,
                                analysis_sources,
                                ownership,
                                variant_path_map,
                            )
                        )

            self._progress(
                f"captured {len(sources)} sources in {len(contexts)} contexts; "
                f"{len(active_contexts)} contexts are active"
            )
            for context_index, (
                root,
                context,
                analysis_sources,
                ownership,
                context_path_map,
            ) in enumerate(active_contexts, 1):
                self._progress(
                    f"context {context_index}/{len(active_contexts)} "
                    f"{root.root_id}: {len(analysis_sources)} source files"
                )
                if cfg.skip_lsp:
                    self._record_skipped_context(
                        context, analysis_sources, "--skip-lsp"
                    )
                    continue
                candidate_count, worker_count = self._analyze_context(
                    root,
                    context,
                    analysis_sources,
                    context_path_map,
                    logical_sources,
                    ownership,
                )
                self._progress(
                    f"context {context_index}/{len(active_contexts)} complete: "
                    f"{candidate_count} candidates across {worker_count} sessions"
                )
        finally:
            analysis_workspace.cleanup()

        self._resolve_pending_external_targets()

        public_sources = [self._public_source(source) for source in sources.values()]
        resolution = self._resolution_lock(all_states, stdlib)
        writer = SnapshotWriter(cfg.output)
        self._progress("writing and validating atomic snapshot")
        try:
            for source in sources.values():
                if Path(source["_realpath"]).read_bytes() != source["_blob"]:
                    raise RuntimeError(f"source changed after analysis: {source['_realpath']}")
                actual = writer.write_blob(source["_blob"])
                if actual != source["blob_digest"]:
                    raise RuntimeError(f"source changed during capture: {source['_realpath']}")
            for asset in self.assets:
                real = Path(asset.pop("_realpath"))
                if real.read_bytes() != asset["_blob"]:
                    raise RuntimeError(f"asset changed after capture: {real}")
                raw = asset.pop("_blob")
                actual = writer.write_blob(raw)
                if actual != asset["blob_digest"]:
                    raise RuntimeError(f"asset changed during capture: {asset['path']}")
            public_inputs = []
            for item in self.analysis_inputs:
                raw = item.pop("_blob")
                real_value = item.pop("_realpath", None)
                if real_value is not None:
                    real = Path(real_value)
                    current = real.read_bytes()
                    if item["kind"] == "package-metadata":
                        current = self._normalize_metadata(current)
                    if digest_bytes(current) != item["blob_digest"]:
                        raise RuntimeError(
                            f"analysis input changed after capture: {real}"
                        )
                if writer.write_blob(raw) != item["blob_digest"]:
                    raise RuntimeError(f"analysis input changed during capture: {item['path']}")
                public_inputs.append(item)
            writer.write_shard("resolution-lock.json", resolution)
            writer.write_table("analysis-inputs.jsonl", public_inputs, ("root_id", "kind", "path"))
            writer.write_table("sources.jsonl", public_sources, ("source_id",))
            writer.write_table("assets.jsonl", self.assets, ("asset_id",))
            writer.write_table("contexts.jsonl", contexts, ("context_id",))
            writer.write_table("symbols.jsonl", self.symbols.values(), ("symbol_id",))
            writer.write_table(
                "external-targets.jsonl",
                self.external_targets.values(),
                ("external_target_id",),
            )
            writer.write_table("diagnostics.jsonl", self.diagnostics, ("root_id", "source_id", "kind"))
            for (context_id, source_id), payload in self.occurrence_shards.items():
                writer.write_shard(f"occurrences/{_slug(context_id)}/{_slug(source_id)}.json", payload)
            for (context_id, source_id), payload in self.request_shards.items():
                writer.write_shard(f"requests/{_slug(context_id)}/{_slug(source_id)}.json", payload)
            for hover_id, payload in sorted(self.hovers.items()):
                writer.write_shard(f"hovers/{hover_id.removeprefix('sha256:')}.json", {"hover_id": hover_id, **payload})
            manifest = writer.publish({
                "analyzer": ANALYZER_VERSION,
                "backend": cfg.backend,
                "toolchain": self.toolchain,
                "resolution_digest": digest_json(resolution),
                "counts": {
                    "sources": len(public_sources), "contexts": len(contexts), "symbols": len(self.symbols),
                    "assets": len(self.assets), "hovers": len(self.hovers),
                    "occurrences": sum(len(value["occurrences"]) for value in self.occurrence_shards.values()),
                    "requests": sum(len(value["requests"]) for value in self.request_shards.values()),
                    "external_targets": len(self.external_targets),
                },
                "partial": not cfg.strict,
                "analysis": {
                    "origins": list(cfg.semantic_origins),
                    "external_targets": "mooncakes",
                },
            })
            self._progress(
                f"published snapshot with {manifest['counts']['occurrences']} occurrences"
            )
            return manifest
        except BaseException:
            writer.abort()
            raise

    def _check_barrier(self, root: Root) -> bool:
        if self.config.skip_check:
            self.diagnostics.append({"root_id": root.root_id, "source_id": "", "kind": "check", "status": "skipped", "message": "--skip-check"})
            return True
        args = [self.config.moon, "-C", str(root.path), "check"]
        if root.entry_file:
            args.append(root.entry_file.name)
        args.extend(["--target", root.backend])
        result = self.config.runner.run(args, timeout=self.config.timeout)
        output = self._portable_diagnostic((result.stdout + result.stderr).decode("utf-8", "replace"), root)
        expected = root.status == "expected-failure"
        degradable = root.status == "display-only"
        ok = result.returncode == 0
        status = (
            "matched-expected-failure" if expected and not ok
            else "expected-failure-no-fatal-error" if expected
            else "complete" if ok
            else "display-only-check-failed" if degradable
            else "failed"
        )
        self.diagnostics.append({
            "root_id": root.root_id, "source_id": "", "kind": "check", "status": status,
            "returncode": result.returncode, "message": output,
        })
        if not expected and not degradable and not ok:
            if self.config.strict:
                raise CommandError(result)
            return False
        return True if expected else ok

    def _record_policy_skip(self, root: Root, origin: str) -> None:
        self.diagnostics.append({
            "root_id": root.root_id,
            "source_id": "",
            "kind": "check",
            "status": "skipped-semantic-origin",
            "message": f"{origin} is outside semantic_origins",
        })

    def _analyze_context(
        self,
        root: Root,
        context: dict[str, Any],
        input_sources: list[dict[str, Any]],
        path_to_source: dict[Path, dict[str, Any]],
        logical_sources: dict[str, dict[str, Any]],
        ownership: PackageOwnership,
    ) -> tuple[int, int]:
        analyzable = [
            source
            for source in sorted(input_sources, key=lambda value: value["source_id"])
            if source["kind"] in {"mbt", "mbt.md"}
            and source["analysis_status"] != "display-only"
        ]
        if not analyzable:
            return 0, 0
        primary = (
            self.config.lsp_factory(root)
            if self.config.lsp_factory
            else LspSession(
                JsonRpcProcess(
                    [self.config.moon_lsp, "--stdio"],
                    root.path,
                    self.config.timeout,
                ),
                root.path,
            )
        )
        try:
            def discover(source: dict[str, Any]) -> tuple[str, list[dict[str, Any]]]:
                path = Path(source["_realpath"])
                coordinates = SourceCoordinates(source["_blob"])
                return (
                    source["source_id"],
                    self._candidates(
                        path,
                        source,
                        coordinates,
                        primary.position_encoding,
                    ),
                )

            with ThreadPoolExecutor(
                max_workers=min(self.config.sessions, len(analyzable)),
                thread_name_prefix="moonbit-semantic-candidates",
            ) as executor:
                candidates_by_source = dict(executor.map(discover, analyzable))
        except BaseException:
            primary.close()
            raise
        candidate_count = sum(len(values) for values in candidates_by_source.values())
        worker_count = min(
            self.config.sessions,
            len(analyzable),
            max(
                1,
                (candidate_count + self.config.positions_per_session - 1)
                // self.config.positions_per_session,
            ),
        )
        self._progress(
            f"{root.root_id}: collected {candidate_count} candidates; "
            f"using {worker_count} LSP sessions"
        )
        chunks: list[list[dict[str, Any]]] = [[] for _ in range(worker_count)]
        chunk_sizes = [0] * worker_count
        for source in sorted(
            analyzable,
            key=lambda value: (
                -len(candidates_by_source[value["source_id"]]),
                -len(value["_blob"]),
                value["source_id"],
            ),
        ):
            index = min(range(worker_count), key=lambda value: (chunk_sizes[value], value))
            chunks[index].append(source)
            chunk_sizes[index] += max(
                1, len(candidates_by_source[source["source_id"]])
            )
        for chunk in chunks:
            chunk.sort(key=lambda value: value["source_id"])

        def analyze_chunk(item: tuple[int, list[dict[str, Any]]]) -> str:
            index, chunk = item
            session = primary if index == 0 else (
                self.config.lsp_factory(root)
                if self.config.lsp_factory
                else LspSession(
                    JsonRpcProcess(
                        [self.config.moon_lsp, "--stdio"],
                        root.path,
                        self.config.timeout,
                    ),
                    root.path,
                )
            )
            try:
                for source in chunk:
                    self._analyze_source(
                        session,
                        context,
                        source,
                        path_to_source,
                        logical_sources,
                        ownership,
                        candidates_by_source[source["source_id"]],
                    )
                return session.position_encoding
            finally:
                session.close()

        if worker_count == 1:
            encodings = [analyze_chunk((0, chunks[0]))]
        else:
            with ThreadPoolExecutor(
                max_workers=worker_count,
                thread_name_prefix="moonbit-semantic-session",
            ) as executor:
                encodings = list(executor.map(analyze_chunk, enumerate(chunks)))
        if len(set(encodings)) != 1:
            raise RuntimeError(
                f"LSP sessions negotiated inconsistent position encodings: {encodings}"
            )
        context["position_encoding"] = encodings[0]
        context["initialize"] = {
            "root_uri": _portable_root_uri(root),
            "position_encoding": encodings[0],
        }
        return candidate_count, worker_count

    def _progress(self, message: str) -> None:
        if not self.config.progress:
            return
        elapsed = time.monotonic() - self._started_at
        with self._progress_lock:
            print(f"[semantic {elapsed:8.1f}s] {message}", file=sys.stderr, flush=True)

    def _resolve_pending_external_targets(self) -> None:
        """Resolve unique external locations after every LSP context closes."""

        if self._mooncakes is None:
            self._finalize_external_navigation()
            return
        pending: dict[
            str, tuple[DefinitionEvidence, list[dict[str, Any]]]
        ] = {}
        for shard in self.occurrence_shards.values():
            for occurrence in shard["occurrences"]:
                for definition in occurrence.get("definitions", []):
                    raw = definition.get("_external_evidence")
                    if not isinstance(raw, dict):
                        continue
                    evidence = DefinitionEvidence(
                        module=str(raw.get("module") or ""),
                        requested_version=str(
                            raw.get("requested_version") or ""
                        ),
                        package=str(raw.get("package") or ""),
                        file=str(raw.get("file") or ""),
                        line=raw.get("line"),
                        column=raw.get("column"),
                    )
                    key = digest_json(raw)
                    if key not in pending:
                        pending[key] = (evidence, [])
                    pending[key][1].append(definition)
        if not pending:
            self._finalize_external_navigation()
            return

        ordered = [pending[key] for key in sorted(pending)]
        workers = min(16, self.config.jobs, len(ordered))
        self._progress(
            f"resolving {len(ordered)} unique Mooncakes definition locations "
            f"with {workers} workers"
        )
        with ThreadPoolExecutor(
            max_workers=workers,
            thread_name_prefix="moonbit-semantic-mooncakes",
        ) as executor:
            resolutions = list(
                executor.map(
                    self._mooncakes.resolve,
                    (evidence for evidence, _definitions in ordered),
                )
            )

        for (evidence, definitions), resolution in zip(ordered, resolutions):
            self.diagnostics.append({
                "root_id": "",
                "source_id": "",
                "kind": "mooncakes-definition",
                "status": resolution.status,
                "reason": resolution.reason,
                "module": evidence.module,
                "package": evidence.package,
            })
            if resolution.exact:
                record = self._external_target_record(resolution)
                target_id = (
                    "mooncakes:"
                    + digest_json(record).removeprefix("sha256:")
                )
                record["external_target_id"] = target_id
                self.external_targets[target_id] = record
                for definition in definitions:
                    definition.pop("_external_evidence", None)
                    definition["external_target_id"] = target_id
                    definition["external_status"] = "exact"
            else:
                for definition in definitions:
                    definition.pop("_external_evidence", None)
                    definition["external_status"] = resolution.status
        self._finalize_external_navigation()

    def _finalize_external_navigation(self) -> None:
        """Collapse proven public aliases without guessing unresolved symbols."""

        for shard in self.occurrence_shards.values():
            for occurrence in shard["occurrences"]:
                definitions = occurrence.get("definitions", [])
                chosen: str | None = None
                if definitions and all(
                    definition.get("external_status") is not None
                    for definition in definitions
                ):
                    exact = []
                    for definition in definitions:
                        target_id = definition.get("external_target_id")
                        target = self.external_targets.get(target_id)
                        if (
                            definition.get("external_status") == "exact"
                            and target is not None
                            and target.get("status") == "exact"
                        ):
                            exact.append((target_id, target))

                    def one_route(
                        values: list[tuple[str, dict[str, Any]]],
                    ) -> str | None:
                        urls = {target["url"] for _target_id, target in values}
                        if len(urls) != 1:
                            return None
                        return min(
                            target_id
                            for target_id, target in values
                            if target["url"] in urls
                        )

                    all_candidates_are_exact = len(exact) == len(definitions)
                    chosen = (
                        one_route(exact)
                        if all_candidates_are_exact
                        else None
                    )
                    if chosen is None and exact:
                        aliases = occurrence.get("_navigation_aliases")
                        qualifier = occurrence.get("_navigation_qualifier")
                        package = (
                            aliases.get(qualifier)
                            if isinstance(aliases, dict)
                            and isinstance(qualifier, str)
                            else None
                        )
                        if package:
                            chosen = one_route(
                                [
                                    item
                                    for item in exact
                                    if item[1].get("package") == package
                                ]
                            )
                        elif qualifier is None:
                            chosen = one_route(
                                [
                                    item
                                    for item in exact
                                    if item[1].get("package")
                                    == "moonbitlang/core/prelude"
                                ]
                            )
                if chosen is not None:
                    occurrence["preferred_external_target_id"] = chosen
                occurrence.pop("_navigation_aliases", None)
                occurrence.pop("_navigation_qualifier", None)

    @staticmethod
    def _external_target_record(
        resolution: MooncakesResolution,
    ) -> dict[str, Any]:
        return {
            "provider": resolution.provider,
            "module": resolution.module,
            "requested_version": resolution.requested_version,
            "resolved_version": resolution.resolved_version,
            "package": resolution.package,
            "anchor": resolution.fragment,
            "symbol_kind": resolution.symbol_kind,
            "url": resolution.url,
            "match": "location",
            "status": "exact",
        }

    def _record_skipped_context(self, context: dict[str, Any], input_sources: list[dict[str, Any]], reason: str) -> None:
        for source in input_sources:
            if source["kind"] not in {"mbt", "mbt.md"} or source["analysis_status"] == "display-only":
                continue
            key = (context["context_id"], source["source_id"])
            self.request_shards[key] = {
                "context_id": key[0], "source_id": key[1],
                "requests": [{"status": "skipped-with-reason", "reason": reason}],
            }
            self.occurrence_shards[key] = {"context_id": key[0], "source_id": key[1], "occurrences": []}

    def _analyze_source(
        self,
        session: LspSession,
        context: dict[str, Any],
        source: dict[str, Any],
        path_to_source: dict[Path, dict[str, Any]],
        logical_sources: dict[str, dict[str, Any]],
        ownership: PackageOwnership,
        candidates: list[dict[str, Any]] | None = None,
    ) -> None:
        path = Path(source["_realpath"])
        raw = source["_blob"]
        coords = SourceCoordinates(raw)
        uri = session.open(path, raw.decode("utf-8"))
        requests = []
        occurrences = []
        try:
            if candidates is None:
                candidates = self._candidates(
                    path, source, coords, session.position_encoding
                )
            positions = [candidate["position"] for candidate in candidates]
            batch_method = getattr(session, "hover_definitions", None)
            if batch_method is not None:
                responses = batch_method(uri, positions, window=self.config.jobs)
            else:
                def query(position: dict[str, int]) -> tuple[Any, Any, str]:
                    return (
                        session.hover(uri, position),
                        session.definition(uri, position),
                        "requested",
                    )

                with ThreadPoolExecutor(
                    max_workers=min(self.config.jobs, max(1, len(positions))),
                    thread_name_prefix="moonbit-semantic-request",
                ) as executor:
                    responses = list(executor.map(query, positions))
            for candidate, (hover, definition, hover_status) in zip(candidates, responses):
                request = {
                    "position": candidate["position"],
                    "candidate_range_utf8": candidate["range_utf8"],
                    "status": "complete",
                    "hover_status": hover_status,
                    "definition_status": "requested",
                }
                try:
                    if isinstance(hover, BaseException):
                        raise hover
                    if isinstance(definition, BaseException):
                        raise definition
                    occurrence = self._occurrence(
                        source,
                        context,
                        candidate,
                        hover,
                        definition,
                        path_to_source,
                        logical_sources,
                        ownership,
                        session.position_encoding,
                    )
                    if occurrence:
                        occurrences.append(occurrence)
                    if not hover and not definition:
                        request["status"] = "valid-no-result"
                except (LspError, RangeError, ValueError, KeyError) as exc:
                    request["status"] = "error"
                    request["error"] = self._portable_text(str(exc))
                    if self.config.strict:
                        raise
                requests.append(request)
        finally:
            session.close_document(uri)
        key = (context["context_id"], source["source_id"])
        self.request_shards[key] = {"context_id": key[0], "source_id": key[1], "requests": requests}
        self.occurrence_shards[key] = {"context_id": key[0], "source_id": key[1], "occurrences": _deduplicate_occurrences(occurrences)}

    def _candidates(self, path: Path, source: dict[str, Any], coords: SourceCoordinates, encoding: str) -> list[dict[str, Any]]:
        temporary = tempfile.NamedTemporaryFile(prefix="moonbit-candidate-", suffix=".mbt", delete=False)
        candidate_blob = source["_blob"]
        if source["kind"] == "mbt.md":
            candidate_blob = moonbit_projection(candidate_blob, source.get("literate_fences", []))
        temporary.write(candidate_blob)
        temporary.close()
        mooninfo_path = Path(temporary.name)
        try:
            result = self.config.runner.run([self.config.mooninfo, "-dump-tokens", str(mooninfo_path), "-o", "-"], cwd=path.parent, timeout=self.config.timeout)
        finally:
            Path(temporary.name).unlink(missing_ok=True)
        if result.returncode:
            if self.config.strict:
                raise CommandError(result)
            return []
        try:
            tokens = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"mooninfo returned invalid JSON for {path}") from exc
        candidates = []
        analyzed_fences = [item["raw_byte_range"] for item in source.get("literate_fences", []) if item["semantic_status"] == "analyzed"]
        for token in tokens:
            value = token.get("token") if isinstance(token, dict) else None
            kind = value[0] if isinstance(value, list) and value else value
            match = LOC.match(token.get("loc", "")) if isinstance(token, dict) else None
            if kind not in IDENTIFIER_TOKENS or not match:
                continue
            sl, sc, el, ec = (int(part) for part in match.groups())
            scalar_range = {"start": {"line": sl - 1, "character": sc - 1}, "end": {"line": el - 1, "character": ec - 1}}
            byte_range = coords.range_to_bytes(scalar_range, "utf-32")
            if source["kind"] == "mbt.md" and not any(start <= byte_range[0] and byte_range[1] <= end for start, end in analyzed_fences):
                continue
            candidates.append({
                "token_kind": kind,
                "range_utf8": byte_range,
                "position": coords.byte_to_position(byte_range[0], encoding),
            })
        return candidates

    def _occurrence(
        self,
        source: dict[str, Any],
        context: dict[str, Any],
        candidate: dict[str, Any],
        hover: Any,
        definition: Any,
        path_to_source: dict[Path, dict[str, Any]],
        logical_sources: dict[str, dict[str, Any]],
        ownership: PackageOwnership,
        encoding: str,
    ) -> dict[str, Any] | None:
        coords = SourceCoordinates(source["_blob"])
        normalized_hover = None
        hover_range = None
        if isinstance(hover, dict):
            normalized_hover = normalize_hover_contents(hover.get("contents"))
            if isinstance(hover.get("range"), dict):
                hover_range = coords.range_to_bytes(hover["range"], encoding)
        hover_id = None
        if normalized_hover and normalized_hover["value"]:
            hover_id = digest_json(normalized_hover)
            with self._semantic_lock:
                self.hovers[hover_id] = normalized_hover
        definitions = []
        for location in definition_locations(definition):
            target_path = _file_uri(location.pop("uri"))
            target = path_to_source.get(realpath(target_path))
            if target is None:
                target = logical_sources.get(_logical_definition_path(target_path))
            if target is None:
                if self.config.strict:
                    raise ValueError(f"definition target is outside captured corpus: {target_path}")
                continue
            target_coords = SourceCoordinates(target["_blob"])
            target_range = target_coords.range_to_bytes(location.pop("target_range"), encoding)
            selection = target_coords.range_to_bytes(location.pop("target_selection_range"), encoding)
            origin = location.pop("origin_selection_range")
            definition_item = {
                **location,
                "target_source_id": target["source_id"],
                "target_range_utf8": target_range,
                "target_selection_range_utf8": selection,
            }
            if origin:
                definition_item["origin_selection_range_utf8"] = coords.range_to_bytes(origin, encoding)
            definition_kind = _definition_kind(target["_blob"], selection)
            symbol_id = _symbol_id(target["source_id"], selection, definition_kind)
            at_definition = source["source_id"] == target["source_id"] and candidate["range_utf8"] == selection
            with self._semantic_lock:
                symbol = self.symbols.get(symbol_id)
                if symbol is None:
                    symbol = {
                        "symbol_id": symbol_id,
                        "definition_source_id": target["source_id"],
                        "selection_range_utf8": selection,
                        "target_range_utf8": target_range,
                        "kind": definition_kind,
                        "hover_id": hover_id if at_definition else None,
                    }
                    self.symbols[symbol_id] = symbol
                elif at_definition and hover_id and not symbol.get("hover_id"):
                    symbol["hover_id"] = hover_id
            definition_item["symbol_id"] = symbol_id
            if target["origin"] in {"dependency", "stdlib"}:
                owned = ownership.resolve_location(target_path)
                if owned is None:
                    owned = ownership.resolve_location(target["_realpath"])
                if owned is None:
                    definition_item["external_status"] = "package-not-indexed"
                elif self._mooncakes is None:
                    definition_item["external_status"] = "provider-disabled"
                else:
                    package, relative_file = owned
                    position = target_coords.byte_to_position(
                        selection[0], "utf-32"
                    )
                    definition_item["_external_evidence"] = {
                        "module": target["module"],
                        "requested_version": target["version"],
                        "package": package,
                        "file": relative_file,
                        "line": position["line"] + 1,
                        "column": position["character"] + 1,
                    }
            definitions.append(definition_item)
        if not hover_id and not definitions:
            return None
        effective = hover_range or candidate["range_utf8"]
        occurrence = {
            "source_id": source["source_id"], "context_id": context["context_id"],
            "request_position": candidate["position"], "candidate_range_utf8": candidate["range_utf8"],
            "hover_range_utf8": hover_range, "effective_range_utf8": effective,
            "hover_id": hover_id, "definitions": sorted(definitions, key=lambda value: (value["target_source_id"], value["target_selection_range_utf8"])),
        }
        aliases = ownership.aliases_for(Path(source["_realpath"]))
        qualifier = _navigation_qualifier(source["_blob"], effective)
        if aliases:
            occurrence["_navigation_aliases"] = aliases
        if qualifier:
            occurrence["_navigation_qualifier"] = qualifier
        return occurrence

    def _context_sources(self, root: Root, metadata: dict[str, Any] | None, path_to_source: dict[Path, dict[str, Any]]) -> list[dict[str, Any]]:
        # packages.json is the exact checked graph.  Scanning dependency module
        # roots here pulls nested examples into the wrong LSP context and can attach
        # plausible-but-wrong semantics.  Files outside this graph remain in the
        # snapshot corpus and receive a separate context (or an explicit status).
        paths = metadata_sources(metadata) if metadata else set(scan_sources(root.path))
        return sorted({path_to_source[path]["source_id"]: path_to_source[path] for path in paths if path in path_to_source}.values(), key=lambda value: value["source_id"])

    @staticmethod
    def _canonical_local_source_ids(
        root_states: dict[str, tuple[Root, dict[str, Any] | None]],
        path_to_source: dict[Path, dict[str, Any]],
    ) -> dict[str, set[str]]:
        """Assign each local source to its most specific discovered root.

        A workspace container and its member modules can all read the same
        workspace ``packages.json``.  Nested path-dependency fixtures have the
        same shape.  Context input graphs may overlap, but semantic occurrence
        ledgers must have one canonical owner, so the deepest containing root
        owns each local source before backend variants are constructed.
        """

        roots = [root for root, _metadata in root_states.values()]
        owned = {root.root_id: set() for root in roots}
        for path, source in path_to_source.items():
            if source["origin"] not in {"local", "standalone"}:
                continue
            containing = [root for root in roots if is_within(path, root.path)]
            if not containing:
                raise RuntimeError(
                    f"local source has no discovered semantic root: {path}"
                )
            depth = max(len(root.path.parts) for root in containing)
            candidates = [
                root for root in containing if len(root.path.parts) == depth
            ]
            if len(candidates) != 1:
                raise RuntimeError(
                    f"local source has ambiguous semantic roots: {path}"
                )
            owned[candidates[0].root_id].add(source["source_id"])
        return owned

    def _analysis_sources(
        self, root: Root, sources: list[dict[str, Any]]
    ) -> list[dict[str, Any]]:
        if root.status != "required":
            return []
        if root.root_id.startswith("dependency:"):
            context_origin = "dependency"
        elif root.root_id.startswith("stdlib:"):
            context_origin = "stdlib"
        elif root.root_id.startswith("standalone:"):
            context_origin = "standalone"
        else:
            context_origin = "local"
        if context_origin not in self.config.semantic_origins:
            return []
        return [
            source
            for source in sources
            if source["origin"] in self.config.semantic_origins
            and source["kind"] in {"mbt", "mbt.md"}
            and source["analysis_status"]
            not in {"display-only", "deferred-by-origin-policy"}
        ]

    def _context_variants(
        self,
        root: Root,
        metadata: dict[str, Any] | None,
        path_to_source: dict[Path, dict[str, Any]],
        workspace: Path,
        owned_source_ids: set[str] | None,
    ) -> list[
        tuple[
            Root,
            dict[str, Any] | None,
            dict[Path, dict[str, Any]],
            set[str] | None,
            dict[str, str],
            str | None,
        ]
    ]:
        metadata_digest = self._package_metadata_digest(metadata)
        base = (
            root,
            metadata,
            path_to_source,
            owned_source_ids,
            {},
            metadata_digest,
        )
        if (
            metadata is None
            or root.status != "required"
            or not root.root_id.startswith("root:")
        ):
            return [base]

        assignments = metadata_source_backends(
            metadata, root.path, root.backend
        )
        groups: dict[str, set[str]] = {}
        for path, backend in assignments.items():
            source = path_to_source.get(realpath(path))
            if source is None or source["origin"] not in {"local", "standalone"}:
                continue
            groups.setdefault(backend, set()).add(source["source_id"])
        if owned_source_ids is not None:
            groups = {
                backend: source_ids & owned_source_ids
                for backend, source_ids in groups.items()
                if source_ids & owned_source_ids
            }
        if not groups:
            return [base]

        order = {name: index for index, name in enumerate(
            ("wasm-gc", "wasm", "js", "native", "llvm")
        )}
        variants = []
        for backend in sorted(
            groups,
            key=lambda value: (
                value != root.backend,
                order.get(value, len(order)),
                value,
            ),
        ):
            allowed = groups[backend]
            if backend == root.backend:
                variants.append(
                    (
                        root,
                        metadata,
                        path_to_source,
                        allowed,
                        {},
                        metadata_digest,
                    )
                )
                continue
            variants.append(
                self._shadow_context_variant(
                    root,
                    metadata,
                    backend,
                    path_to_source,
                    workspace,
                    allowed,
                )
            )
        return variants

    def _shadow_context_variant(
        self,
        root: Root,
        metadata: dict[str, Any],
        backend: str,
        path_to_source: dict[Path, dict[str, Any]],
        workspace: Path,
        allowed_source_ids: set[str],
    ) -> tuple[
        Root,
        dict[str, Any],
        dict[Path, dict[str, Any]],
        set[str],
        dict[str, str],
        str,
    ]:
        suffix = digest_json(
            {"root_id": root.root_id, "backend": backend}
        ).removeprefix("sha256:")[:16]
        ignored = {".git", ".hg", ".svn", "_build", "target", "node_modules", ".mooncakes"}

        def ignore(_directory: str, names: list[str]) -> set[str]:
            return set(names) & ignored

        original_owner = nearest_workspace(root.path) or root.path
        if not is_within(original_owner, self.config.repo_root):
            raise RuntimeError(
                f"alternate-target root is outside repository: {root.path}"
            )
        shadow_repo = workspace / f"{suffix}-{backend}" / "repo"
        shadow_owner = _copy_repo_overlay(
            self.config.repo_root,
            original_owner,
            shadow_repo,
            ignored,
            ignore,
        )
        _link_mooncakes_trees(original_owner, shadow_owner, ignored)
        shadow_path = shadow_owner / root.path.relative_to(original_owner)
        _set_preferred_target(shadow_path, backend)
        shadow_owner = realpath(shadow_owner)
        shadow_path = realpath(shadow_path)
        owner_relative = normalize_relative(
            original_owner.relative_to(self.config.repo_root)
        )
        self.portable_roots[shadow_owner] = (
            "$REPO" + (f"/{owner_relative}" if owner_relative else "")
        )
        shadow = Root(
            shadow_path,
            f"{root.root_id}@{backend}",
            root.status,
            root.module_name,
            root.version,
            backend,
            (
                shadow_path / root.entry_file.relative_to(root.path)
                if root.entry_file is not None
                else None
            ),
        )
        self._progress(
            f"checking alternate target {backend} for {root.root_id}"
        )
        self._check_barrier(shadow)

        generated_metadata, _generated_path = package_metadata(shadow)
        shadow_metadata = (
            generated_metadata
            if generated_metadata is not None
            else _replace_path_prefix(
                metadata,
                original_owner,
                shadow_owner,
            )
        )
        metadata_digest = self._package_metadata_digest(shadow_metadata)
        if metadata_digest is None:
            raise RuntimeError(
                f"alternate target produced no package metadata: {shadow.root_id}"
            )
        self._captured_input(
            json.dumps(
                shadow_metadata,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
            + b"\n",
            "package-metadata-variant",
            shadow.root_id,
            f"alternate-target/{_slug(shadow.root_id)}.packages.json",
        )
        aliases = dict(path_to_source)
        physical_paths: dict[str, str] = {}
        for original, source in path_to_source.items():
            if not is_within(original, original_owner):
                continue
            relative = original.relative_to(original_owner)
            candidate = shadow_owner / relative
            if not candidate.is_file():
                continue
            candidate = realpath(candidate)
            if candidate.read_bytes() != source["_blob"]:
                raise RuntimeError(
                    f"alternate target shadow differs from source: {original}"
                )
            aliases[candidate] = source
            if source["source_id"] in allowed_source_ids:
                physical_paths[source["source_id"]] = str(candidate)
        missing = allowed_source_ids - physical_paths.keys()
        if missing:
            raise RuntimeError(
                f"alternate target shadow is missing sources: {sorted(missing)}"
            )
        return (
            shadow,
            shadow_metadata,
            aliases,
            allowed_source_ids,
            physical_paths,
            metadata_digest,
        )

    def _context(
        self,
        root: Root,
        sources: list[dict[str, Any]],
        analysis_sources: list[dict[str, Any]],
        package_metadata_digest: str | None,
    ) -> dict[str, Any]:
        inputs = [{"source_id": source["source_id"], "blob_digest": source["blob_digest"]} for source in sources]
        analysis_source_ids = sorted(
            source["source_id"] for source in analysis_sources
        )
        analysis = {
            "origins": list(self.config.semantic_origins),
            "source_ids": analysis_source_ids,
        }
        fingerprint = {
            "root_id": root.root_id,
            "module": root.module_name,
            "backend": root.backend,
            "toolchain": digest_json(self.toolchain),
            "inputs": inputs,
            "analysis": analysis,
            "package_metadata_digest": package_metadata_digest,
        }
        context_id = "ctx:" + digest_json(fingerprint).removeprefix("sha256:")[:32]
        return {
            "context_id": context_id, "root_id": root.root_id, "package": root.module_name,
            "file_role": "module", "backend": root.backend, "input_source_ids": [item["source_id"] for item in inputs],
            "input_blobs": inputs, "context_input_digest": digest_json(fingerprint), "analysis_status": root.status,
            "analysis_origins": list(self.config.semantic_origins),
            "analysis_source_ids": analysis_source_ids,
            "package_metadata_digest": package_metadata_digest,
            "toolchain_digest": digest_json(self.toolchain), "position_encoding": "utf-16", "initialize": {},
        }

    def _add_source(self, source: dict[str, Any], sources: dict[str, dict[str, Any]], path_map: dict[Path, dict[str, Any]]) -> None:
        path = realpath(Path(source["_realpath"]))
        old = path_map.get(path)
        priority = {"local": 4, "standalone": 3, "dependency": 2, "stdlib": 1}
        if old and priority[old["origin"]] >= priority[source["origin"]]:
            return
        if old:
            sources.pop(old["source_id"], None)
        if source["source_id"] in sources and sources[source["source_id"]]["blob_digest"] != source["blob_digest"]:
            raise RuntimeError(f"source identity collision: {source['source_id']}")
        sources[source["source_id"]] = source
        path_map[path] = source

    def _input(self, path: Path, kind: str, root_id: str) -> None:
        raw = path.read_bytes()
        try:
            portable = normalize_relative(path.resolve().relative_to(self.config.repo_root))
        except ValueError:
            portable = path.name
        captured = self._normalize_metadata(raw) if kind == "package-metadata" else raw
        self.analysis_inputs.append({
            "root_id": root_id, "kind": kind, "path": portable,
            "blob_digest": digest_bytes(captured), "normalized": captured != raw,
            "_realpath": str(path.resolve()), "_blob": captured,
        })

    def _captured_input(
        self,
        raw: bytes,
        kind: str,
        root_id: str,
        portable_path: str,
    ) -> None:
        """Freeze an ephemeral analysis input before its workspace is removed."""

        captured = (
            self._normalize_metadata(raw)
            if kind.startswith("package-metadata")
            else raw
        )
        self.analysis_inputs.append(
            {
                "root_id": root_id,
                "kind": kind,
                "path": portable_path,
                "blob_digest": digest_bytes(captured),
                "normalized": captured != raw,
                "_blob": captured,
            }
        )

    def _package_metadata_digest(
        self, metadata: dict[str, Any] | None
    ) -> str | None:
        if metadata is None:
            return None
        raw = (
            json.dumps(
                metadata,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
            + b"\n"
        )
        return digest_bytes(self._normalize_metadata(raw))

    @staticmethod
    def _verify_precheck(root: Root, captured: dict[Path, bytes]) -> None:
        current_paths = set(scan_sources(root.path))
        if current_paths != set(captured):
            raise RuntimeError(f"source inventory changed across moon check: {root.root_id}")
        changed = [str(path) for path, raw in captured.items() if path.read_bytes() != raw]
        if changed:
            raise RuntimeError(f"source bytes changed across moon check for {root.root_id}: {changed}")

    def _normalize_metadata(self, raw: bytes) -> bytes:
        try:
            value = json.loads(raw)
        except (UnicodeDecodeError, json.JSONDecodeError):
            return raw

        def visit(item: Any) -> Any:
            if isinstance(item, dict):
                result = {}
                for key, value in item.items():
                    normalized_key = visit(key) if isinstance(key, str) else key
                    if normalized_key in result:
                        raise RuntimeError(f"package metadata key collision after path normalization: {normalized_key}")
                    result[normalized_key] = visit(value)
                return result
            if isinstance(item, list):
                return [visit(value) for value in item]
            if isinstance(item, str):
                # Command arrays contain compound values such as
                # ``package:/absolute/path``.  Normalize known root prefixes in
                # every string before applying the standalone-path fallback.
                for original, replacement in sorted(
                    ((str(path), label) for path, label in self.portable_roots.items()),
                    key=lambda value: len(value[0]), reverse=True,
                ):
                    item = item.replace(original, replacement)
                if not Path(item).is_absolute():
                    return item
                path = Path(item)
                if is_within(path, self.config.repo_root):
                    return "$REPO/" + normalize_relative(realpath(path).relative_to(self.config.repo_root))
                if self.config.stdlib_root and is_within(path, self.config.stdlib_root):
                    return "$STDLIB/" + normalize_relative(realpath(path).relative_to(self.config.stdlib_root))
                for parent in (path.parent, *path.parents):
                    if (parent / "moon.mod").is_file() or (parent / "moon.mod.json").is_file():
                        info = module_info(parent)
                        try:
                            relative = normalize_relative(realpath(path).relative_to(realpath(parent)))
                        except ValueError:
                            break
                        return f"$MODULE/{info['name']}@{info['version'] or _source_tree_digest(parent)[7:23]}/{relative}"
                return "$EXTERNAL/" + path.name
            return item

        return json.dumps(visit(value), ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8") + b"\n"

    def _register_portable_root(self, root: Path) -> None:
        root = realpath(root)
        info = module_info(root)
        version = info["version"] or _source_tree_digest(root).removeprefix("sha256:")[:16]
        self.portable_roots[root] = f"$MODULE/{info['name']}@{version}"

    def _portable_diagnostic(self, value: str, root: Root) -> str:
        return self._portable_text(value, root)

    def _portable_text(self, value: str, root: Root | None = None) -> str:
        replacements = {
            str(path): label for path, label in self.portable_roots.items()
        }
        if root is not None:
            replacements[str(root.path)] = "$ROOT"
        for original, replacement in sorted(
            replacements.items(), key=lambda item: len(item[0]), reverse=True
        ):
            value = value.replace(original, replacement)
        return value

    def _manifest_inputs(self, root: Root) -> None:
        for filename in ("moon.work", "moon.mod", "moon.mod.json"):
            path = root.path / filename
            if path.is_file():
                self._input(path, "moon-manifest", root.root_id)
        for path in sorted(root.path.rglob("moon.pkg")) + sorted(root.path.rglob("moon.pkg.json")):
            if "_build" not in path.parts:
                self._input(path, "package-manifest", root.root_id)

    def _resolution_lock(self, states: list[tuple[Root, dict[str, Any] | None]], stdlib: Path | None) -> dict[str, Any]:
        modules = []
        for root, _ in states:
            info = module_info(root.path)
            source_digests = [{"path": normalize_relative(path.relative_to(root.path)), "digest": digest_bytes(path.read_bytes())} for path in scan_sources(root.path)]
            modules.append({
                "root_id": root.root_id, "module": info["name"], "version": info["version"],
                "license": info["license"], "repository": info["repository"],
                "tree_digest": digest_json(source_digests), "package_set": [],
                "origin": "stdlib" if stdlib and root.path == stdlib else "dependency" if root.root_id.startswith("dependency:") else "local",
            })
        return {"schema": "moonbit-resolution-lock/v1", "modules": sorted(modules, key=lambda value: value["root_id"])}

    def _toolchain(self) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, command, args in (("moon", self.config.moon, ["version", "--all"]), ("moon_lsp", self.config.moon_lsp, ["--version"]), ("mooninfo", self.config.mooninfo, ["--help"])):
            executable = shutil.which(command)
            version = self.config.runner.run([command, *args], timeout=10)
            result[key] = {
                "version": (version.stdout + version.stderr).decode("utf-8", "replace").splitlines()[0] if version.stdout or version.stderr else "",
                "executable_digest": digest_bytes(Path(executable).read_bytes()) if executable and Path(executable).is_file() else "unavailable",
            }
        return result

    def _find_stdlib(self) -> Path | None:
        value = os.environ.get("MOON_HOME")
        candidates = [Path(value) / "lib/core"] if value else []
        moon = shutil.which(self.config.moon)
        if moon:
            candidates.append(Path(moon).resolve().parent.parent / "lib/core")
        candidates.append(Path.home() / ".moon/lib/core")
        return next((candidate.resolve() for candidate in candidates if candidate.is_dir()), None)

    @staticmethod
    def _public_source(source: dict[str, Any]) -> dict[str, Any]:
        return {key: value for key, value in source.items() if not key.startswith("_")}


def _copy_repo_overlay(
    repo_root: Path,
    owner: Path,
    destination: Path,
    ignored: set[str],
    ignore: Callable[[str, list[str]], set[str]],
) -> Path:
    """Copy one module/workspace while symlinking its repository siblings.

    Recreating the ancestor layout keeps workspace membership and repository-
    relative path dependencies valid without copying the whole documentation
    tree for every alternate backend.
    """

    repo_root = realpath(repo_root)
    owner = realpath(owner)
    relative = owner.relative_to(repo_root)
    original_cursor = repo_root
    shadow_cursor = destination
    shadow_cursor.mkdir(parents=True, exist_ok=True)

    for part in relative.parts:
        for sibling in original_cursor.iterdir():
            if sibling.name == part or sibling.name in ignored:
                continue
            link = shadow_cursor / sibling.name
            if link.exists() or link.is_symlink():
                continue
            os.symlink(
                sibling,
                link,
                target_is_directory=sibling.is_dir(),
            )
        original_cursor /= part
        shadow_cursor /= part
        shadow_cursor.mkdir(exist_ok=True)

    shutil.copytree(
        owner,
        shadow_cursor,
        symlinks=True,
        ignore=ignore,
        dirs_exist_ok=True,
    )
    return shadow_cursor


def _link_mooncakes_trees(
    original_owner: Path,
    shadow_owner: Path,
    ignored: set[str],
) -> None:
    """Restore ignored dependency stores as read-only symlinked inputs."""

    for current, directories, _files in os.walk(original_owner):
        current_path = Path(current)
        relative = current_path.relative_to(original_owner)
        for name in list(directories):
            if name == ".mooncakes":
                source = current_path / name
                target = shadow_owner / relative / name
                target.parent.mkdir(parents=True, exist_ok=True)
                if not target.exists() and not target.is_symlink():
                    os.symlink(source, target, target_is_directory=True)
        directories[:] = [
            name for name in directories if name not in ignored
        ]


def _set_preferred_target(root: Path, backend: str) -> None:
    json_manifest = root / "moon.mod.json"
    if json_manifest.is_file():
        try:
            value = json.loads(json_manifest.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise RuntimeError(
                f"cannot rewrite alternate-target manifest: {json_manifest}"
            ) from exc
        if not isinstance(value, dict):
            raise RuntimeError(
                f"alternate-target manifest is not an object: {json_manifest}"
            )
        value["preferred-target"] = backend
        json_manifest.write_text(
            json.dumps(value, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return

    manifest = root / "moon.mod"
    if manifest.is_file():
        text = manifest.read_text(encoding="utf-8")
        replacement = f'preferred_target = "{backend}"'
        if re.search(r"^\s*preferred_target\s*=", text, re.MULTILINE):
            text = re.sub(
                r'^\s*preferred_target\s*=\s*"[^"]*"',
                replacement,
                text,
                count=1,
                flags=re.MULTILINE,
            )
        else:
            text = text.rstrip() + "\n" + replacement + "\n"
        manifest.write_text(text, encoding="utf-8")
        return

    raise RuntimeError(
        f"alternate-target analysis requires a module manifest below {root}"
    )


def _replace_path_prefix(value: Any, original: Path, replacement: Path) -> Any:
    source = str(realpath(original))
    target = str(realpath(replacement))
    if isinstance(value, dict):
        return {
            _replace_path_prefix(key, original, replacement): _replace_path_prefix(
                item, original, replacement
            )
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [_replace_path_prefix(item, original, replacement) for item in value]
    if isinstance(value, str):
        return value.replace(source, target)
    return value


def _navigation_qualifier(raw: bytes, byte_range: list[int]) -> str | None:
    """Return the explicit ``@alias`` immediately qualifying an occurrence."""

    end = byte_range[1]
    line_start = raw.rfind(b"\n", 0, end) + 1
    try:
        prefix = raw[line_start:end].decode("utf-8")
    except UnicodeDecodeError:
        return None
    match = re.search(r"@([A-Za-z_][A-Za-z0-9_]*)\.[A-Za-z0-9_]*$", prefix)
    return match.group(1) if match else None


def _portable_root_uri(root: Root) -> str:
    return "moonbit-root://" + root.root_id.replace("/", "%2F")


def _file_uri(uri: str) -> Path:
    parsed = urlparse(uri)
    if parsed.scheme != "file" or parsed.netloc not in ("", "localhost"):
        raise ValueError(f"unsupported definition URI: {uri}")
    return Path(unquote(parsed.path))


def _logical_definition_path(path: Path) -> str:
    return unicodedata.normalize("NFC", path.as_posix().replace("\\", "/").lstrip("/"))


def _logical_source_map(values: Any) -> dict[str, dict[str, Any]]:
    candidates: dict[str, list[dict[str, Any]]] = {}
    for source in values:
        module = str(source.get("module") or "").strip("/")
        path = str(source.get("path") or "").replace("\\", "/").lstrip("/")
        if not module or not path:
            continue
        keys = {f"{module}/{path}"}
        if path.startswith("src/"):
            keys.add(f"{module}/{path.removeprefix('src/')}")
        for key in keys:
            candidates.setdefault(unicodedata.normalize("NFC", key), []).append(source)
    return {
        key: sources[0]
        for key, sources in candidates.items()
        if len({source["source_id"] for source in sources}) == 1
    }


def _symbol_id(source_id: str, selection: list[int], kind: str) -> str:
    return "sym:" + digest_json({"source": source_id, "selection": selection, "kind": kind}).removeprefix("sha256:")[:32]


def _definition_kind(raw: bytes, selection: list[int]) -> str:
    try:
        text = raw[selection[0] : selection[1]].decode("utf-8")
    except (UnicodeDecodeError, IndexError):
        return "identifier"
    value = text.lstrip(".@~?")
    return "UIDENT" if value[:1].isupper() else "LIDENT"


def _slug(value: str) -> str:
    return digest_bytes(value.encode()).removeprefix("sha256:")[:32]


def _source_tree_digest(root: Path) -> str:
    rows = [
        {"path": normalize_relative(path.relative_to(root)), "digest": digest_bytes(path.read_bytes())}
        for path in scan_sources(root)
    ]
    return digest_json(rows)


def _deduplicate_occurrences(values: list[dict[str, Any]]) -> list[dict[str, Any]]:
    unique = {digest_json(value): value for value in values}
    return sorted(unique.values(), key=lambda value: (value["effective_range_utf8"], value.get("hover_id") or ""))
