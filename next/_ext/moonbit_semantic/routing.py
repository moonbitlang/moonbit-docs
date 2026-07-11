"""Stable, portable pagenames and anchors for semantic source pages."""

from __future__ import annotations

import hashlib
import re
from urllib.parse import quote

from .snapshot import DefinitionTarget, Source, Symbol


def _segment(value: str) -> str:
    # route_key is an indexer-owned, already percent-escaped identity.
    return quote(value, safe="._-~%") or "_"


def source_pagename(prefix: str, source: Source) -> str:
    if source.route_key:
        parts = [part for part in source.route_key.replace("\\", "/").split("/") if part not in {"", "."}]
        if ".." in parts:
            raise ValueError(f"unsafe source route key: {source.route_key!r}")
        return "/".join([prefix.strip("/")] + [_segment(part) for part in parts])
    identity = [source.origin]
    if source.module:
        identity.append(source.module)
    if source.version:
        identity.append(source.version)
    if source.package and source.package != source.module:
        identity.append(source.package)
    identity.extend(part for part in source.path.replace("\\", "/").split("/") if part)
    return "/".join([prefix.strip("/")] + [_segment(part) for part in identity])


def stable_fragment(value: str) -> str:
    readable = re.sub(r"[^A-Za-z0-9_.-]+", "-", value).strip("-")[:48]
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]
    return f"{readable}-{digest}" if readable else digest


def symbol_anchor(symbol_id: str) -> str:
    return "mb-def-" + stable_fragment(symbol_id)


def target_fingerprint(targets: tuple[DefinitionTarget, ...]) -> str:
    payload = "\n".join(
        f"{item.source_id}:{item.selection_range[0]}:{item.selection_range[1]}:{item.symbol_id or ''}"
        for item in sorted(targets, key=lambda item: (item.source_id, item.selection_range, item.symbol_id or ""))
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:24]


def target_anchor(target: DefinitionTarget, symbols: dict[str, Symbol]) -> str:
    if target.symbol_id and target.symbol_id in symbols:
        return symbol_anchor(target.symbol_id)
    return f"L{target.selection_range[0]}"  # replaced with a real line by the resolver
