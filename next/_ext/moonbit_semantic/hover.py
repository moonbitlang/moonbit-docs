"""Build-time rendering for LSP Hover markup.

Hover content is Markdown, but it is delivered from a static preload so the
documentation also works from ``file://`` URLs.  Render it with the project's
existing MyST/Sphinx/Pygments pipeline once during the build; the browser only
mounts the resulting, sanitised HTML fragment.
"""

from __future__ import annotations

from contextlib import contextmanager
from dataclasses import replace
from html import escape
import re
from typing import Any, Iterator, Mapping
from urllib.parse import urlsplit

from docutils import nodes
from docutils.frontend import get_default_settings
from docutils.utils import new_document
from sphinx.util import logging


LOGGER = logging.getLogger(__name__)
ALLOWED_URI_SCHEMES = {"http", "https", "mailto"}
DIRECTIVE_LANGUAGE = re.compile(r"^\{[^}\r\n]+\}$")


@contextmanager
def _docname(env: Any, value: str) -> Iterator[None]:
    previous = env.temp_data.get("docname")
    env.temp_data["docname"] = value
    try:
        yield
    finally:
        if previous is None:
            env.temp_data.pop("docname", None)
        else:
            env.temp_data["docname"] = previous


@contextmanager
def _hover_markdown_config(env: Any) -> Iterator[None]:
    """Use MyST's CommonMark grammar without executable Sphinx directives.

    LSP ``MarkupContent`` is Markdown rather than a Sphinx source document.
    Keeping the same MyST parser and Sphinx renderer preserves all normal
    Markdown nodes and the standard highlighter while preventing ``include``
    or ``raw`` directives from executing during a documentation build.
    """

    original = env.myst_config
    env.myst_config = replace(
        original,
        commonmark_only=True,
        gfm_only=False,
        enable_extensions=set(),
        fence_as_directive=set(),
        heading_anchors=0,
        html_meta={},
        substitutions={},
    )
    try:
        yield
    finally:
        env.myst_config = original


def _markup_content(payload: Any) -> tuple[str, str]:
    if isinstance(payload, str):
        return "plaintext", payload
    if isinstance(payload, Mapping) and isinstance(payload.get("value"), str):
        kind = payload.get("kind")
        return ("markdown" if kind == "markdown" else "plaintext"), payload["value"]
    return "plaintext", str(payload) if payload is not None else ""


def _plain_fragment(value: str) -> str:
    return (
        '<div class="mbt-hover-markdown bd-content">'
        f'<pre class="mbt-hover-plaintext">{escape(value)}</pre>'
        "</div>"
    )


def _drop_unsafe_reference(node: nodes.reference) -> None:
    replacement = nodes.inline(node.rawsource, "", classes=["mbt-hover-unsafe-link"])
    replacement.extend(node.children)
    node.children = []
    node.replace_self(replacement)


def _sanitize_document(document: nodes.document) -> None:
    # GFM still recognises raw HTML.  Preserve it as readable text rather than
    # allowing arbitrary LSP documentation to become active DOM.
    for node in list(document.findall(nodes.raw)):
        text = node.astext()
        replacement: nodes.Node
        if "\n" in text:
            replacement = nodes.literal_block(node.rawsource, text)
        else:
            replacement = nodes.literal(node.rawsource, text)
        node.replace_self(replacement)

    for node in list(document.findall(nodes.reference)):
        uri = str(node.get("refuri") or "")
        if uri and urlsplit(uri).scheme.lower() not in ALLOWED_URI_SCHEMES:
            _drop_unsafe_reference(node)

    for node in list(document.findall(nodes.image)):
        # Hover fragments have no stable document-relative asset base. Never
        # turn LSP documentation into local or remote image requests.
        node.replace_self(nodes.Text(str(node.get("alt") or "")))

    # A Hover fragment is mounted inside an existing page, so it must not
    # create document-level section ids or permalink anchors.  MyST can also
    # emit visible system messages when a fragment begins at H2/H3.  Preserve
    # heading text as a styled rubric and discard those document diagnostics.
    for node in list(document.findall(nodes.system_message)):
        node.replace_self([])
    for section in reversed(list(document.findall(nodes.section))):
        title = next(
            (child for child in section.children if isinstance(child, nodes.title)),
            None,
        )
        replacement = [child for child in section.children if child is not title]
        if title is not None:
            depth = 1
            parent = section.parent
            while parent is not None:
                if isinstance(parent, nodes.section):
                    depth += 1
                parent = parent.parent
            rubric = nodes.rubric(
                title.rawsource,
                "",
                classes=["mbt-hover-heading", f"mbt-hover-heading-{min(depth, 6)}"],
            )
            rubric.extend(title.children)
            title.children = []
            replacement.insert(0, rubric)
        section.children = []
        section.replace_self(replacement)

    # In the GFM profile, ```{include} is an ordinary fenced block.  Render it
    # as text to avoid an unknown-lexer warning and make the non-execution
    # explicit in the generated output.
    for node in document.findall(nodes.literal_block):
        language = str(node.get("language") or "")
        if DIRECTIVE_LANGUAGE.match(language):
            node["language"] = "text"
            node["classes"] = [
                value for value in node.get("classes", []) if value != language
            ]


def _markdown_fragment(app: Any, hover_id: str, value: str) -> str:
    parser = app.registry.create_source_parser(app, "markdown")
    settings = get_default_settings(parser)
    for key, setting in getattr(app.env, "settings", {}).items():
        setattr(settings, key, setting)
    settings.env = app.env
    settings.warning_stream = None
    document = new_document(f"hover://{hover_id}", settings=settings)
    document["moonbit_semantic_hover"] = True
    with (
        _docname(app.env, f"__mbtsem_hover__/{hover_id}"),
        _hover_markdown_config(app.env),
        logging.suppress_logging(),
    ):
        parser.parse(value, document)
    _sanitize_document(document)

    # ``render_partial(document)`` nests a complete document in another
    # document.  Render only its children so the fragment appears exactly once.
    container = nodes.container("", classes=["mbt-hover-markdown", "bd-content"])
    container.extend(document.children)
    document.children = []
    # Normal document writes set this per docname immediately before creating
    # the HTML translator.  Hover fragments have no figure-numbering context
    # and are rendered earlier so their content hash can enter every page.
    if not hasattr(app.builder, "fignumbers"):
        app.builder.fignumbers = {}
    with logging.suppress_logging():
        return app.builder.render_partial(container)["fragment"]


def render_hover_payloads(app: Any, hovers: Mapping[str, Any]) -> dict[str, dict[str, str]]:
    """Render each distinct Hover to a safe, theme-compatible HTML fragment."""

    rendered: dict[str, dict[str, str]] = {}
    for hover_id, payload in sorted(hovers.items()):
        kind, value = _markup_content(payload)
        try:
            fragment = (
                _markdown_fragment(app, hover_id, value)
                if kind == "markdown"
                else _plain_fragment(value)
            )
        except Exception as exc:
            if app.config.moonbit_semantic_required:
                raise
            LOGGER.warning("MoonBit Hover %s could not be rendered as Markdown: %s", hover_id, exc)
            fragment = _plain_fragment(value)
        rendered[str(hover_id)] = {"kind": "html", "value": fragment}
    return rendered
