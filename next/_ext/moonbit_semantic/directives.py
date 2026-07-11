"""Sphinx directives that preserve semantic source provenance."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

from docutils import nodes
from sphinx.directives.code import LiteralInclude

from .provenance import build_literalinclude_provenance, resolve_snapshot_source


PROVENANCE_ATTRIBUTE = "moonbit_semantic_provenance"


def _literal_blocks(result: Iterable[nodes.Node]) -> Iterable[nodes.literal_block]:
    for root in result:
        if isinstance(root, nodes.literal_block):
            yield root
        if isinstance(root, nodes.Element):
            yield from root.findall(nodes.literal_block)


class SemanticLiteralInclude(LiteralInclude):
    """The Sphinx 8.1 ``literalinclude`` plus a verified range map.

    Rendering is delegated entirely to the upstream directive.  Provenance is
    calculated afterwards and attached only to the resulting literal node, so
    a capture failure cannot change warnings, captions, line numbers, slicing,
    highlighting, or the displayed text.
    """

    def run(self) -> list[nodes.Node]:
        original_options = dict(self.options)
        filename: str | None = None
        raw: bytes | None = None
        try:
            _relative, filename = self.env.relfn2path(self.arguments[0])
            raw = Path(filename).read_bytes()
        except (OSError, ValueError):
            # Upstream remains responsible for the user-facing warning.
            pass

        result = super().run()
        snapshot = getattr(self.env.app, "_moonbit_semantic_snapshot", None)
        if snapshot is None or filename is None or raw is None:
            return result

        source = resolve_snapshot_source(
            snapshot,
            filename,
            raw,
            roots=(self.env.app.srcdir, self.env.app.confdir, Path(self.env.app.confdir).parent),
        )
        effective_options = dict(original_options)
        if "encoding" not in effective_options:
            effective_options["encoding"] = self.config.source_encoding
        for literal in _literal_blocks(result):
            literal[PROVENANCE_ATTRIBUTE] = build_literalinclude_provenance(
                raw,
                literal.astext(),
                effective_options,
                source_id=source.source_id if source is not None else None,
                target=self.arguments[0],
            )
        return result


def register_literalinclude(app: Any) -> None:
    """Install the compatible directive under Sphinx's standard name."""

    app.add_directive("literalinclude", SemanticLiteralInclude, override=True)
