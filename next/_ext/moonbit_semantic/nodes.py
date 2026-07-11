"""Semantic annotations and HTML-only replacement nodes for document blocks."""

from __future__ import annotations

from html import escape
from pathlib import Path
from typing import Any, Mapping

from docutils import nodes
from sphinx.transforms.post_transforms import SphinxPostTransform

from .directives import PROVENANCE_ATTRIBUTE, register_literalinclude
from .provenance import (
    infer_identity_provenance,
    map_occurrences,
    provenance_is_current,
    sha256_text,
)
from .render import SemanticCodeRenderer
from .source_pages import _target_href


OCCURRENCES_ATTRIBUTE = "moonbit_semantic_occurrences"
DISPLAY_DIGEST_ATTRIBUTE = "moonbit_semantic_display_digest"
SOURCE_ID_ATTRIBUTE = "moonbit_semantic_source_id"
MOONBIT_LANGUAGES = {"mbt", "moonbit", "mbt check", "moonbit check"}
SKIP_MARKERS = {"nocheck", "skip", "moonbit skip", "mbt nocheck"}


class SemanticLiteralBlock(nodes.literal_block):
    """A literal block whose HTML was produced by ``SemanticCodeRenderer``."""


def visit_semantic_literal_block(translator: Any, node: SemanticLiteralBlock) -> None:
    translator.body.append(str(node["semantic_html"]))
    raise nodes.SkipNode


def depart_semantic_literal_block(translator: Any, node: SemanticLiteralBlock) -> None:
    return None


def _language(node: nodes.literal_block) -> str:
    language = " ".join(str(node.get("language") or "").lower().split())
    if language:
        return language
    classes = {str(value).lower() for value in node.get("classes", ())}
    return next((value for value in MOONBIT_LANGUAGES if value in classes), "")


def _is_moonbit(node: nodes.literal_block) -> bool:
    language = _language(node)
    classes = {str(value).lower() for value in node.get("classes", ())}
    return language in MOONBIT_LANGUAGES and not (classes & SKIP_MARKERS)


def _roots(app: Any) -> tuple[Path, ...]:
    return (Path(app.srcdir), Path(app.confdir), Path(app.confdir).parent)


def _provenance_for_node(app: Any, node: nodes.literal_block, snapshot: Any) -> Mapping[str, Any] | None:
    provenance = node.get(PROVENANCE_ATTRIBUTE)
    if isinstance(provenance, Mapping):
        return provenance
    source = getattr(node, "source", None) or node.get("source")
    if not source or str(source).startswith("snapshot://"):
        return None
    return infer_identity_provenance(
        snapshot,
        source,
        node.astext(),
        roots=_roots(app),
    )


def annotate_semantic_blocks(app: Any, doctree: nodes.document) -> None:
    """Attach only verified, pickle-safe semantic data after include/i18n."""

    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if snapshot is None or app.builder.name not in {"html", "dirhtml"}:
        return
    env = getattr(doctree.settings, "env", app.env)
    docname = getattr(env, "docname", None) or env.temp_data.get("docname")
    used_sources: set[str] = set()
    for node in doctree.findall(nodes.literal_block):
        if isinstance(node, SemanticLiteralBlock) or not _is_moonbit(node):
            continue
        provenance = _provenance_for_node(app, node, snapshot)
        if provenance is None or not provenance_is_current(provenance, node.astext(), snapshot):
            continue
        source_id = provenance.get("source_id")
        source = snapshot.sources.get(source_id)
        # Inventory status is normally ``required``; actual semantic
        # availability is established by verified occurrences.  Only an
        # explicit display-only source must never receive an overlay.
        if source is None or source.analysis_status == "display-only":
            continue
        occurrences = snapshot.occurrences.get(source_id, ())
        if source.context_id:
            occurrences = tuple(
                occurrence
                for occurrence in occurrences
                if occurrence.context_id in {None, source.context_id}
            )
        mapped = map_occurrences(provenance, occurrences)
        if not mapped:
            continue
        node[PROVENANCE_ATTRIBUTE] = dict(provenance)
        node[OCCURRENCES_ATTRIBUTE] = mapped
        node[DISPLAY_DIGEST_ATTRIBUTE] = sha256_text(node.astext())
        node[SOURCE_ID_ATTRIBUTE] = source_id
        used_sources.add(source_id)
        if docname:
            env.get_domain("mbtsem").note_backlink(docname, source_id)
    if docname:
        store = getattr(env, "moonbit_semantic_block_sources", {})
        store[docname] = used_sources
        env.moonbit_semantic_block_sources = store


def purge_semantic_blocks(app: Any, env: Any, docname: str) -> None:
    store = getattr(env, "moonbit_semantic_block_sources", None)
    if isinstance(store, dict):
        store.pop(docname, None)


def merge_semantic_blocks(app: Any, env: Any, docnames: list[str], other: Any) -> None:
    destination = getattr(env, "moonbit_semantic_block_sources", {})
    source = getattr(other, "moonbit_semantic_block_sources", {})
    for docname in docnames:
        if docname in source:
            destination[docname] = set(source[docname])
    env.moonbit_semantic_block_sources = destination


class SemanticBlockPostTransform(SphinxPostTransform):
    """Replace verified annotations only for HTML-family builders."""

    default_priority = 750
    builders = ("html", "dirhtml")

    def run(self, **kwargs: Any) -> None:
        snapshot = getattr(self.app, "_moonbit_semantic_snapshot", None)
        if snapshot is None:
            return
        docname = self.env.docname
        renderer = SemanticCodeRenderer()
        for node in list(self.document.findall(nodes.literal_block)):
            if isinstance(node, SemanticLiteralBlock):
                continue
            # Keep Sphinx's original renderer whenever presentation options
            # carry meaning that the semantic renderer does not reproduce.
            # This preserves line numbers and emphasized lines byte-for-byte
            # instead of silently weakening existing documentation markup.
            highlight_args = node.get("highlight_args") or {}
            if node.get("linenos") or highlight_args.get("hl_lines"):
                continue
            provenance = node.get(PROVENANCE_ATTRIBUTE)
            occurrences = node.get(OCCURRENCES_ATTRIBUTE)
            if not isinstance(provenance, Mapping) or not occurrences:
                continue
            text = node.astext()
            if (
                node.get(DISPLAY_DIGEST_ATTRIBUTE) != sha256_text(text)
                or not provenance_is_current(provenance, text, snapshot)
            ):
                continue
            # Re-project from the frozen snapshot instead of trusting mutable
            # doctree payloads after deserialisation or third-party transforms.
            source_id = provenance.get("source_id")
            mapped = map_occurrences(provenance, snapshot.occurrences.get(source_id, ()))
            if not mapped:
                continue
            rendered = renderer.render(
                text,
                mapped,
                lambda occurrence: _target_href(self.app, docname, occurrence),
                line_anchors=False,
                source_page=False,
            )
            ids = " ".join(str(value) for value in node.get("ids", ()))
            identity = f' id="{escape(ids.split()[0], quote=True)}"' if ids else ""
            html = f'<div class="mbt-semantic-document-block"{identity}>{rendered}</div>'
            replacement = SemanticLiteralBlock(node.rawsource, text, **dict(node.attributes))
            replacement.source = node.source
            replacement.line = node.line
            replacement["semantic_html"] = html
            node.replace_self(replacement)


def setup_block_semantics(app: Any) -> None:
    """Register the document-block half of the semantic extension."""

    register_literalinclude(app)
    app.add_node(
        SemanticLiteralBlock,
        html=(visit_semantic_literal_block, depart_semantic_literal_block),
    )
    app.add_post_transform(SemanticBlockPostTransform)
    # ``check.py`` uses the default priority (500); semantic capture must see
    # the final literal blocks after that checker and gettext/include work.
    app.connect("doctree-read", annotate_semantic_blocks, priority=600)
    app.connect("env-purge-doc", purge_semantic_blocks)
    app.connect("env-merge-info", merge_semantic_blocks)
