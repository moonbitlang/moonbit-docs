"""End-to-end MoonBit semantic snapshot orchestration."""

from __future__ import annotations

import json
import os
import re
import shutil
import tempfile
import threading
import unicodedata
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable
from urllib.parse import unquote, urlparse

from .canonical import digest_bytes, digest_json, is_within, normalize_relative, realpath
from .inventory import (
    Root, discover_roots, make_source, metadata_allowed_module_roots,
    metadata_sources, module_info, package_metadata, recognized, scan_sources,
)
from .literate import moonbit_projection
from .lsp import JsonRpcProcess, LspError, LspSession, definition_locations, normalize_hover_contents
from .ranges import RangeError, SourceCoordinates
from .runner import CommandError, Runner, SubprocessRunner
from .snapshot import SnapshotWriter

ANALYZER_VERSION = "moonbit-semantic-indexer/1"
LOC = re.compile(r"^(\d+):(\d+)-(\d+):(\d+)$")
IDENTIFIER_TOKENS = {
    "LIDENT", "UIDENT", "DOT_LIDENT", "DOT_UIDENT", "PACKAGE_NAME",
    "LABEL", "QUESTION_LABEL", "POST_LABEL",
}
ASSET = re.compile(rb"(?:!\[[^\]]*\]\(([^)\s]+)|\{(?:include|literalinclude)\}\s+([^\s}]+))")


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
    skip_check: bool = False
    skip_lsp: bool = False
    strict: bool = True
    timeout: float = 120.0
    runner: Runner = field(default_factory=SubprocessRunner)
    lsp_factory: Callable[[Root], LspSession] | None = None

    def __post_init__(self) -> None:
        self.repo_root = self.repo_root.resolve()
        self.source_root = (self.repo_root / self.source_root).resolve() if not self.source_root.is_absolute() else self.source_root.resolve()
        self.output = (self.repo_root / self.output).resolve() if not self.output.is_absolute() else self.output.resolve()
        if self.stdlib_root is not None:
            self.stdlib_root = self.stdlib_root.resolve()
        if self.jobs < 1:
            raise ValueError("jobs must be at least 1")
        if self.sessions < 1:
            raise ValueError("sessions must be at least 1")
        if self.positions_per_session < 1:
            raise ValueError("positions_per_session must be at least 1")


class SemanticIndexer:
    def __init__(self, config: BuildConfig):
        self.config = config
        self.diagnostics: list[dict[str, Any]] = []
        self.analysis_inputs: list[dict[str, Any]] = []
        self.assets: list[dict[str, Any]] = []
        self.hovers: dict[str, dict[str, str]] = {}
        self.symbols: dict[str, dict[str, Any]] = {}
        self.occurrence_shards: dict[tuple[str, str], dict[str, Any]] = {}
        self.request_shards: dict[tuple[str, str], dict[str, Any]] = {}
        self.toolchain: dict[str, Any] = {}
        self.portable_roots: dict[Path, str] = {config.repo_root: "$REPO"}
        self.capture_roots: set[Path] = set()
        self._semantic_lock = threading.Lock()

    def build(self) -> dict[str, Any]:
        cfg = self.config
        roots = discover_roots(cfg.source_root, cfg.backend)
        if not roots:
            raise RuntimeError(f"no MoonBit roots found below {cfg.source_root}")
        self.capture_roots.update(realpath(root.path) for root in roots)
        precheck_sources = {
            root.root_id: {path: path.read_bytes() for path in scan_sources(root.path)}
            for root in roots
        }
        stdlib = cfg.stdlib_root or self._find_stdlib()
        cfg.stdlib_root = stdlib
        if stdlib:
            self.portable_roots[realpath(stdlib)] = "$STDLIB"
            self.capture_roots.add(realpath(stdlib))
        self.toolchain = self._toolchain()
        root_states: dict[str, tuple[Root, dict[str, Any] | None]] = {}
        dependency_roots: set[Path] = set()

        for root in roots:
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
            # A resolved module's page corpus includes auxiliary examples and nested
            # modules which need not be healthy under the consumer's toolchain.  Try
            # its own context, but degrade that context instead of losing all source
            # pages when an unrelated auxiliary package does not check.
            candidate = Root(path, f"dependency:{identity}", "display-only", info["name"], version, info["preferred_target"] or cfg.backend)
            precheck_sources[candidate.root_id] = {source: source.read_bytes() for source in scan_sources(candidate.path)}
            check_ok = self._check_barrier(candidate)
            dep = Root(path, candidate.root_id, "required" if check_ok else "display-only", info["name"], version, candidate.backend)
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

        stdlib_state: tuple[Root, dict[str, Any] | None] | None = None
        if stdlib:
            info = module_info(stdlib)
            version = info["version"] or _source_tree_digest(stdlib).removeprefix("sha256:")[:16]
            stdroot = Root(stdlib, f"stdlib:{info['name']}@{version}", "required", info["name"], version, info["preferred_target"] or cfg.backend)
            # The shipped stdlib already contains a pinned bundle. Check when requested, then
            # verify its source and executable digests as analysis inputs either way.
            precheck_sources[stdroot.root_id] = {source: source.read_bytes() for source in scan_sources(stdroot.path)}
            self._check_barrier(stdroot)
            metadata, metadata_path = package_metadata(stdroot)
            if metadata_path and metadata_path.is_file():
                self._input(metadata_path, "package-metadata", stdroot.root_id)
            stdlib_state = (stdroot, metadata)

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
                source = make_source(path, origin="dependency", base=root.path, module=root.module_name, version=root.version, status="required")
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
                source = make_source(path, origin="stdlib", base=root.path, module=root.module_name, version=root.version, status="required")
                self._add_source(source, sources, path_to_source)
            self._manifest_inputs(root)

        logical_sources = _logical_source_map(sources.values())

        self._collect_assets(sources, path_to_source)
        contexts: list[dict[str, Any]] = []
        all_states = list(root_states.values()) + dependency_states + ([stdlib_state] if stdlib_state else [])
        for root, metadata in all_states:
            input_sources = self._context_sources(root, metadata, path_to_source)
            if not input_sources:
                continue
            context = self._context(root, input_sources)
            contexts.append(context)
            if root.status == "required":
                if cfg.skip_lsp:
                    self._record_skipped_context(context, input_sources, "--skip-lsp")
                else:
                    self._analyze_context(
                        root,
                        context,
                        input_sources,
                        path_to_source,
                        logical_sources,
                    )

        public_sources = [self._public_source(source) for source in sources.values()]
        resolution = self._resolution_lock(all_states, stdlib)
        writer = SnapshotWriter(cfg.output)
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
                real = Path(item.pop("_realpath"))
                current = real.read_bytes()
                if item["kind"] == "package-metadata":
                    current = self._normalize_metadata(current)
                if digest_bytes(current) != item["blob_digest"]:
                    raise RuntimeError(f"analysis input changed after capture: {real}")
                raw = item.pop("_blob")
                if writer.write_blob(raw) != item["blob_digest"]:
                    raise RuntimeError(f"analysis input changed during capture: {item['path']}")
                public_inputs.append(item)
            writer.write_shard("resolution-lock.json", resolution)
            writer.write_table("analysis-inputs.jsonl", public_inputs, ("root_id", "kind", "path"))
            writer.write_table("sources.jsonl", public_sources, ("source_id",))
            writer.write_table("assets.jsonl", self.assets, ("asset_id",))
            writer.write_table("contexts.jsonl", contexts, ("context_id",))
            writer.write_table("symbols.jsonl", self.symbols.values(), ("symbol_id",))
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
                },
                "partial": not cfg.strict,
            })
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

    def _analyze_context(
        self,
        root: Root,
        context: dict[str, Any],
        input_sources: list[dict[str, Any]],
        path_to_source: dict[Path, dict[str, Any]],
        logical_sources: dict[str, dict[str, Any]],
    ) -> None:
        analyzable = [
            source
            for source in sorted(input_sources, key=lambda value: value["source_id"])
            if source["kind"] in {"mbt", "mbt.md"}
            and source["analysis_status"] != "display-only"
        ]
        if not analyzable:
            return
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
                        session.position_encoding,
                    )
                    if occurrence:
                        occurrences.append(occurrence)
                    if not hover and not definition:
                        request["status"] = "valid-no-result"
                except (LspError, RangeError, ValueError, KeyError) as exc:
                    request["status"] = "error"
                    request["error"] = str(exc)
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
            definitions.append(definition_item)
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
        if not hover_id and not definitions:
            return None
        effective = hover_range or candidate["range_utf8"]
        return {
            "source_id": source["source_id"], "context_id": context["context_id"],
            "request_position": candidate["position"], "candidate_range_utf8": candidate["range_utf8"],
            "hover_range_utf8": hover_range, "effective_range_utf8": effective,
            "hover_id": hover_id, "definitions": sorted(definitions, key=lambda value: (value["target_source_id"], value["target_selection_range_utf8"])),
        }

    def _context_sources(self, root: Root, metadata: dict[str, Any] | None, path_to_source: dict[Path, dict[str, Any]]) -> list[dict[str, Any]]:
        # packages.json is the exact checked graph.  Scanning dependency module
        # roots here pulls nested examples into the wrong LSP context and can attach
        # plausible-but-wrong semantics.  Files outside this graph remain in the
        # page corpus and receive a separate context (or an explicit display status).
        paths = metadata_sources(metadata) if metadata else set(scan_sources(root.path))
        return sorted({path_to_source[path]["source_id"]: path_to_source[path] for path in paths if path in path_to_source}.values(), key=lambda value: value["source_id"])

    def _context(self, root: Root, sources: list[dict[str, Any]]) -> dict[str, Any]:
        inputs = [{"source_id": source["source_id"], "blob_digest": source["blob_digest"]} for source in sources]
        fingerprint = {"root_id": root.root_id, "module": root.module_name, "backend": root.backend, "toolchain": digest_json(self.toolchain), "inputs": inputs}
        context_id = "ctx:" + digest_json(fingerprint).removeprefix("sha256:")[:32]
        return {
            "context_id": context_id, "root_id": root.root_id, "package": root.module_name,
            "file_role": "module", "backend": root.backend, "input_source_ids": [item["source_id"] for item in inputs],
            "input_blobs": inputs, "context_input_digest": digest_json(fingerprint), "analysis_status": root.status,
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

    def _collect_assets(self, sources: dict[str, dict[str, Any]], path_map: dict[Path, dict[str, Any]]) -> None:
        for source in list(sources.values()):
            if source["kind"] != "mbt.md":
                continue
            owner = Path(source["_realpath"])
            owner_roots = sorted(
                (root for root in self.capture_roots if is_within(owner, root)),
                key=lambda root: len(root.parts),
                reverse=True,
            )
            if not owner_roots:
                continue
            capture_root = owner_roots[0]
            # MyST root-relative links in next/sources/*.mbt.md are relative to
            # the Sphinx source root (next/), not to the Moon module.
            document_root = (
                self.config.source_root.parent
                if is_within(owner, self.config.source_root)
                else capture_root
            )
            self._assets_from(
                owner,
                source["source_id"],
                set(),
                path_map,
                capture_root=capture_root,
                document_root=document_root,
            )

    def _assets_from(
        self,
        owner: Path,
        owner_id: str,
        visited: set[Path],
        path_map: dict[Path, dict[str, Any]],
        *,
        capture_root: Path,
        document_root: Path,
        depth: int = 0,
    ) -> None:
        if depth > 16:
            raise RuntimeError(f"literate asset recursion exceeds limit at {owner}")
        raw = owner.read_bytes()
        for match in ASSET.finditer(raw):
            value = next((group for group in match.groups() if group), b"").decode("utf-8", "replace").strip("<>\"'")
            if not value or "://" in value or value.startswith("#"):
                continue
            reference = value.split("#", 1)[0]
            target = realpath(
                document_root / reference.lstrip("/")
                if reference.startswith("/")
                else owner.parent / reference
            )
            if target in visited or not target.is_file():
                continue
            allowed_roots = (capture_root, document_root)
            logical_root = next(
                (root for root in allowed_roots if is_within(target, root)),
                None,
            )
            if logical_root is None:
                if self.config.strict:
                    raise RuntimeError(f"literate asset escapes allowed roots: {target}")
                continue
            visited.add(target)
            blob = target.read_bytes()
            logical_path = unicodedata.normalize(
                "NFC", normalize_relative(target.relative_to(logical_root))
            )
            asset_id = "asset:" + digest_json({"owner": owner_id, "path": logical_path, "blob": digest_bytes(blob)}).removeprefix("sha256:")[:24]
            self.assets.append({
                "asset_id": asset_id, "owner_source_id": owner_id, "path": logical_path,
                "blob_digest": digest_bytes(blob), "mime": _mime(target), "_realpath": str(target), "_blob": blob,
            })
            if target.suffix.lower() in {".md", ".markdown"}:
                self._assets_from(
                    target,
                    owner_id,
                    visited,
                    path_map,
                    capture_root=capture_root,
                    document_root=document_root,
                    depth=depth + 1,
                )

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
        self.capture_roots.add(root)

    def _portable_diagnostic(self, value: str, root: Root) -> str:
        replacements = [(str(self.config.repo_root), "$REPO"), (str(root.path), "$ROOT")]
        if self.config.stdlib_root:
            replacements.append((str(self.config.stdlib_root), "$STDLIB"))
        for original, replacement in sorted(replacements, key=lambda item: len(item[0]), reverse=True):
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


def _mime(path: Path) -> str:
    return {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".svg": "image/svg+xml", ".md": "text/markdown"}.get(path.suffix.lower(), "application/octet-stream")


def _source_tree_digest(root: Path) -> str:
    rows = [
        {"path": normalize_relative(path.relative_to(root)), "digest": digest_bytes(path.read_bytes())}
        for path in scan_sources(root)
    ]
    return digest_json(rows)


def _deduplicate_occurrences(values: list[dict[str, Any]]) -> list[dict[str, Any]]:
    unique = {digest_json(value): value for value in values}
    return sorted(unique.values(), key=lambda value: (value["effective_range_utf8"], value.get("hover_id") or ""))
