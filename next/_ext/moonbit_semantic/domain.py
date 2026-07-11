"""Sphinx domain exposing frozen MoonBit definitions to xrefs/inventory."""

from __future__ import annotations

from collections import defaultdict
from typing import Any, Iterable

from docutils import nodes
from sphinx import addnodes
from sphinx.domains import Domain, Index, ObjType
from sphinx.roles import XRefRole

from .routing import source_pagename, symbol_anchor


class MoonBitSourceIndex(Index):
    name = "source"
    localname = "MoonBit source files"
    shortname = "Source"

    def generate(self, docnames: Iterable[str] | None = None) -> tuple[list[tuple[str, list[Any]]], bool]:
        grouped: dict[str, list[Any]] = defaultdict(list)
        for source_id, value in self.domain.data.get("sources", {}).items():
            title, pagename, package = value
            key = (package or title or source_id)[0].upper()
            grouped[key].append((title, 0, pagename, "", package, "", ""))
        return sorted((key, sorted(values)) for key, values in grouped.items()), False


class MoonBitSymbolIndex(Index):
    name = "symbol"
    localname = "MoonBit symbols"
    shortname = "Symbols"

    def generate(self, docnames: Iterable[str] | None = None) -> tuple[list[tuple[str, list[Any]]], bool]:
        grouped: dict[str, list[Any]] = defaultdict(list)
        for symbol_id, value in self.domain.data.get("symbols", {}).items():
            name, pagename, anchor, kind, package, _source_id = value
            key = (name or symbol_id)[0].upper()
            grouped[key].append((name, 0, pagename, anchor, package, kind, symbol_id))
        return sorted((key, sorted(values)) for key, values in grouped.items()), False


class MoonBitSemanticDomain(Domain):
    name = "mbtsem"
    label = "MoonBit semantic source"
    object_types = {
        "symbol": ObjType("symbol", "symbol"),
        "source": ObjType("source", "source"),
    }
    roles = {"symbol": XRefRole(), "source": XRefRole()}
    indices = [MoonBitSourceIndex, MoonBitSymbolIndex]
    initial_data = {"sources": {}, "symbols": {}, "backlinks": {}}
    data_version = 1

    def register_snapshot(self, snapshot: Any, prefix: str) -> None:
        self.data["sources"] = {
            source.source_id: (
                source.title or source.path,
                source_pagename(prefix, source),
                source.package,
            )
            for source in snapshot.sources.values()
        }
        self.data["symbols"] = {
            symbol.symbol_id: (
                symbol.qualified_name or symbol.name,
                source_pagename(prefix, snapshot.sources[symbol.source_id]),
                symbol_anchor(symbol.symbol_id),
                symbol.kind,
                symbol.package,
                symbol.source_id,
            )
            for symbol in snapshot.symbols.values()
        }

    def note_backlink(self, docname: str, source_id: str) -> None:
        self.data.setdefault("backlinks", {}).setdefault(source_id, set()).add(docname)

    def clear_doc(self, docname: str) -> None:
        for values in self.data.get("backlinks", {}).values():
            values.discard(docname)

    def merge_domaindata(self, docnames: list[str], otherdata: dict[str, Any]) -> None:
        # Snapshot-derived maps are identical in every worker; only backlinks
        # are genuinely worker-local.
        self.data["sources"].update(otherdata.get("sources", {}))
        self.data["symbols"].update(otherdata.get("symbols", {}))
        for source_id, values in otherdata.get("backlinks", {}).items():
            self.data.setdefault("backlinks", {}).setdefault(source_id, set()).update(values)

    def resolve_xref(
        self,
        env: Any,
        fromdocname: str,
        builder: Any,
        typ: str,
        target: str,
        node: addnodes.pending_xref,
        contnode: nodes.Element,
    ) -> nodes.reference | None:
        table = self.data["symbols"] if typ == "symbol" else self.data["sources"]
        value = table.get(target)
        if value is None:
            return None
        pagename = value[1]
        anchor = value[2] if typ == "symbol" else ""
        uri = builder.get_relative_uri(fromdocname, pagename)
        if anchor:
            uri += "#" + anchor
        return nodes.reference("", "", contnode, refuri=uri, internal=True)

    def resolve_any_xref(self, env: Any, fromdocname: str, builder: Any, target: str, node: Any, contnode: Any) -> list[Any]:
        result = []
        for typ in ("symbol", "source"):
            resolved = self.resolve_xref(env, fromdocname, builder, typ, target, node, contnode)
            if resolved is not None:
                result.append((f"mbtsem:{typ}", resolved))
        return result

    def get_objects(self) -> Iterable[tuple[str, str, str, str, str, int]]:
        for source_id, (title, pagename, _package) in self.data.get("sources", {}).items():
            yield source_id, title, "source", pagename, "", 1
        for symbol_id, (name, pagename, anchor, _kind, _package, _source) in self.data.get("symbols", {}).items():
            yield symbol_id, name, "symbol", pagename, anchor, 1
