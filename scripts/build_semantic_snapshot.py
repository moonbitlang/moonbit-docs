#!/usr/bin/env python3
"""Build or validate a self-contained MoonBit semantic documentation snapshot."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from moonbit_semantic import BuildConfig, SemanticIndexer, SnapshotError, validate_snapshot


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)
    build = commands.add_parser("build", help="analyze source and atomically publish a snapshot")
    build.add_argument("--repo-root", type=Path, default=Path.cwd())
    build.add_argument("--source-root", type=Path, default=Path("next/sources"))
    build.add_argument("--output", type=Path, default=Path("semantic-snapshot"))
    build.add_argument("--stdlib-root", type=Path)
    build.add_argument("--backend", default="wasm-gc")
    build.add_argument("--moon", default="moon")
    build.add_argument("--mooninfo", default="mooninfo")
    build.add_argument("--moon-lsp", default="moon-lsp")
    build.add_argument(
        "--jobs",
        type=int,
        default=max(8, min(64, (os.cpu_count() or 1) * 8)),
        help="maximum in-flight semantic positions per LSP session",
    )
    build.add_argument(
        "--sessions",
        type=int,
        default=max(1, min(8, os.cpu_count() or 1)),
        help="maximum asynchronous LSP sessions for a large context",
    )
    build.add_argument("--skip-check", action="store_true", help="testing only: do not establish the moon check barrier")
    build.add_argument("--skip-lsp", action="store_true", help="testing only: capture corpus without semantic requests")
    build.add_argument("--allow-partial", action="store_true", help="record tool failures instead of failing closed")
    validate = commands.add_parser("validate", help="validate all snapshot files, hashes, and references")
    validate.add_argument("--snapshot", type=Path, default=Path("semantic-snapshot"))
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "validate":
            manifest = validate_snapshot(args.snapshot)
        else:
            config = BuildConfig(
                repo_root=args.repo_root, source_root=args.source_root, output=args.output,
                stdlib_root=args.stdlib_root, backend=args.backend, moon=args.moon,
                mooninfo=args.mooninfo, moon_lsp=args.moon_lsp,
                jobs=args.jobs, sessions=args.sessions,
                skip_check=args.skip_check, skip_lsp=args.skip_lsp, strict=not args.allow_partial,
            )
            manifest = SemanticIndexer(config).build()
        print(json.dumps({"schema": manifest["schema"], "corpus_digest": manifest["corpus_digest"], "counts": manifest["counts"]}, sort_keys=True))
        return 0
    except (OSError, RuntimeError, SnapshotError, ValueError) as exc:
        print(f"semantic snapshot: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
