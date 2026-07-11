"""Pickle-safe document destinations and fail-closed Definition routing."""

from __future__ import annotations

import hashlib
from typing import Any, Iterable, Mapping

from .snapshot import DefinitionTarget, Occurrence, SemanticSnapshot


DEFINITION_STORE_ATTRIBUTE = "moonbit_semantic_document_definitions"
DefinitionKey = tuple[str, str, int, int]
DefinitionDestination = tuple[int, str]


def definition_key(
    source_id: str,
    symbol_id: str | None,
    byte_range: tuple[int, int],
) -> DefinitionKey:
    """Return the exact source identity shared by a target and declaration."""

    return source_id, symbol_id or "", byte_range[0], byte_range[1]


def definition_anchor(
    docname: str,
    block_ordinal: int,
    source_id: str,
    symbol_id: str | None,
    byte_range: tuple[int, int],
) -> str:
    """Return an ID unique to one displayed definition in one document block."""

    payload = "\0".join(
        (
            docname,
            str(block_ordinal),
            source_id,
            symbol_id or "",
            str(byte_range[0]),
            str(byte_range[1]),
        )
    )
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    return f"mb-def-doc-{block_ordinal}-{digest}"


def displayed_definition_key(
    symbol_id: str | None, byte_range: tuple[int, int]
) -> tuple[str, int, int]:
    """Key an anchor against the post-projection occurrence range."""

    return symbol_id or "", byte_range[0], byte_range[1]


def replace_document_definitions(
    env: Any,
    docname: str,
    values: Mapping[DefinitionKey, Iterable[DefinitionDestination]],
) -> None:
    """Atomically replace all destinations contributed by one doctree read."""

    store = getattr(env, DEFINITION_STORE_ATTRIBUTE, {})
    store[docname] = {
        key: sorted(set(destinations), key=lambda item: (item[0], item[1]))
        for key, destinations in values.items()
    }
    setattr(env, DEFINITION_STORE_ATTRIBUTE, store)


def purge_document_definitions(env: Any, docname: str) -> None:
    store = getattr(env, DEFINITION_STORE_ATTRIBUTE, None)
    if isinstance(store, dict):
        store.pop(docname, None)


def merge_document_definitions(
    env: Any, docnames: Iterable[str], other: Any
) -> None:
    destination = getattr(env, DEFINITION_STORE_ATTRIBUTE, {})
    source = getattr(other, DEFINITION_STORE_ATTRIBUTE, {})
    for docname in docnames:
        if docname in source:
            destination[docname] = {
                key: list(values) for key, values in source[docname].items()
            }
        else:
            destination.pop(docname, None)
    setattr(env, DEFINITION_STORE_ATTRIBUTE, destination)


def _document_destination(
    env: Any, target: DefinitionTarget
) -> tuple[str, str] | None:
    key = definition_key(
        target.source_id,
        target.symbol_id,
        target.selection_range,
    )
    candidates: list[tuple[str, int, str]] = []
    store = getattr(env, DEFINITION_STORE_ATTRIBUTE, {})
    for docname, definitions in store.items():
        for ordinal, anchor in definitions.get(key, ()):
            candidates.append((docname, ordinal, anchor))
    if not candidates:
        return None
    docname, _ordinal, anchor = min(candidates, key=lambda item: item)
    return docname, anchor


def resolve_definition_target(
    app: Any,
    fromdocname: str,
    snapshot: SemanticSnapshot,
    target: DefinitionTarget,
) -> str | None:
    """Resolve one target to an exact external or displayed-document route."""

    if target.external_target_id is not None:
        if target.external_status != "exact":
            return None
        external = snapshot.external_targets.get(target.external_target_id)
        if external is None or external.status != "exact":
            return None
        return external.url

    source = snapshot.sources.get(target.source_id)
    if source is None or source.origin not in {"local", "standalone"}:
        return None
    destination = _document_destination(app.env, target)
    if destination is None:
        return None
    docname, anchor = destination
    return app.builder.get_relative_uri(fromdocname, docname) + "#" + anchor


def resolve_occurrence_target(
    app: Any,
    fromdocname: str,
    snapshot: SemanticSnapshot,
    occurrence: Occurrence,
) -> str | None:
    """Resolve a Definition result only when its public route is unambiguous.

    The index may persist a canonical public target after proving an import
    alias or prelude re-export.  Older snapshots still require every LSP
    location to resolve to the same href.
    """

    if not occurrence.definitions:
        return None
    if occurrence.preferred_external_target_id is not None:
        if any(
            target.external_status is None
            or snapshot.sources.get(target.source_id) is None
            or snapshot.sources[target.source_id].origin
            in {"local", "standalone"}
            for target in occurrence.definitions
        ):
            return None
        preferred = [
            target
            for target in occurrence.definitions
            if target.external_status == "exact"
            and target.external_target_id
            == occurrence.preferred_external_target_id
        ]
        if not preferred:
            return None
        resolved_preferred = {
            resolve_definition_target(app, fromdocname, snapshot, target)
            for target in preferred
        }
        if None in resolved_preferred or len(resolved_preferred) != 1:
            return None
        return next(iter(resolved_preferred))
    resolved = [
        resolve_definition_target(app, fromdocname, snapshot, target)
        for target in occurrence.definitions
    ]
    if any(href is None for href in resolved):
        return None
    unique = set(resolved)
    return next(iter(unique)) if len(unique) == 1 else None
