"""Extension-owned MyST virtual doctrees for frozen ``.mbt.md`` sources."""

from __future__ import annotations

from contextlib import contextmanager
from copy import deepcopy
from dataclasses import replace
import re
from typing import Any, Iterator

from docutils import nodes
from docutils.frontend import get_default_settings
from docutils.utils import new_document
from sphinx.errors import ExtensionError
from sphinx.util import logging
from sphinx.util.osutil import relative_uri

from .render import SemanticCodeRenderer


LOGGER = logging.getLogger(__name__)
VIRTUAL_KEY = "moonbit_semantic_literate_doctrees"
MOONBIT_LANGUAGES = {"mbt", "moonbit", "moonbit check", "mbt check"}
INCLUDE = re.compile(
    r"(?ms)^(?P<mark>`{3,}|~{3,})\{(?P<kind>include|literalinclude)\}\s+(?P<path>[^\r\n]+)\r?\n.*?^(?P=mark)\s*$"
)
IMAGE = re.compile(r"(!\[[^\]]*\]\()(?P<path>[^)\s]+)(?P<tail>[^)]*\))")
DIRECTIVE = re.compile(r"(?m)^(?:`{3,}|~{3,})\{(?P<name>[^}]+)\}")
SAFE_DIRECTIVES = {"code-block", "note", "warning", "tip", "important", "admonition"}


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


def prepare_literate_doctrees(app: Any, env: Any, docnames: list[str]) -> None:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if snapshot is None or app.builder.name not in {"html", "dirhtml"}:
        return
    store: dict[str, nodes.document] = {}
    for source in snapshot.sources.values():
        if not source.literate:
            continue
        text = _snapshot_backed_markdown(app, source, snapshot.source_text(source))
        virtual_docname = f"__mbtsem__/{source.source_id}"
        parser = app.registry.create_source_parser(app, "markdown")
        settings = get_default_settings(parser)
        for key, value in getattr(env, "settings", {}).items():
            setattr(settings, key, value)
        settings.env = env
        settings.warning_stream = None
        document = new_document(f"snapshot://{source.source_id}", settings=settings)
        document["source_id"] = source.source_id
        try:
            with _docname(env, virtual_docname):
                parser.parse(text, document)
        except Exception as exc:
            if app.config.moonbit_semantic_required:
                raise
            LOGGER.warning("MoonBit literate source %s could not be parsed: %s", source.source_id, exc)
            continue
        if source.origin in {"dependency", "stdlib"}:
            # Dependency Markdown is untrusted input.  Raw HTML is shown as
            # text; it is never allowed into the generated site DOM.
            for raw_node in list(document.findall(nodes.raw)):
                raw_node.replace_self(nodes.literal(raw_node.rawsource, raw_node.astext()))
        store[source.source_id] = document
    setattr(env, VIRTUAL_KEY, store)


def _snapshot_backed_markdown(app: Any, source: Any, text: str) -> str:
    """Resolve includes/images only from frozen assets, never the checkout."""
    snapshot = app._moonbit_semantic_snapshot
    assets = [asset for asset in snapshot.assets.values() if asset.owner_source_id == source.source_id]

    def find_asset(value: str) -> Any | None:
        normalized = value.strip().strip("<>\"'").split("#", 1)[0].replace("\\", "/").lstrip("/")
        exact = [asset for asset in assets if asset.path.replace("\\", "/") == normalized]
        if exact:
            return exact[0]
        by_name = [asset for asset in assets if asset.path.replace("\\", "/").rsplit("/", 1)[-1] == normalized.rsplit("/", 1)[-1]]
        return by_name[0] if len(by_name) == 1 else None

    def include(match: re.Match[str]) -> str:
        asset = find_asset(match.group("path"))
        if asset is None:
            message = f"literate include is not frozen for {source.source_id}: {match.group('path').strip()}"
            if app.config.moonbit_semantic_required:
                raise ExtensionError(message)
            LOGGER.warning(message)
            return f"> MoonBit semantic source omitted an unfrozen include: `{match.group('path').strip()}`"
        try:
            body = snapshot.asset_bytes(asset).decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ExtensionError(f"literate text include is not UTF-8: {asset.path}") from exc
        if match.group("kind") == "include":
            return body
        suffix = asset.path.rsplit(".", 1)[-1].lower()
        language = "moonbit" if suffix in {"mbt", "mbti", "mbtp"} else suffix
        return f"```{language}\n{body.rstrip()}\n```"

    # Recursion is deliberately bounded even though the indexer already
    # checks its resource closure.
    for _ in range(16):
        replaced = INCLUDE.sub(include, text)
        if replaced == text:
            break
        text = replaced
    else:
        raise ExtensionError(f"literate include expansion exceeds limit: {source.source_id}")

    def image(match: re.Match[str]) -> str:
        asset = find_asset(match.group("path"))
        if asset is None:
            message = f"literate image is not frozen for {source.source_id}: {match.group('path')}"
            if app.config.moonbit_semantic_required:
                raise ExtensionError(message)
            LOGGER.warning(message)
            return match.group(0)
        return f"{match.group(1)}mbt-asset:{asset.asset_id}{match.group('tail')}"

    text = IMAGE.sub(image, text)
    unsafe = sorted({match.group("name").strip().lower() for match in DIRECTIVE.finditer(text)} - SAFE_DIRECTIVES)
    if unsafe:
        message = f"unsafe or unfrozen literate directives in {source.source_id}: {', '.join(unsafe)}"
        if app.config.moonbit_semantic_required:
            raise ExtensionError(message)
        LOGGER.warning(message)
        # Escaping the opening marker preserves readable prose without
        # executing a directive in the non-strict fallback.
        text = DIRECTIVE.sub(lambda match: "\\" + match.group(0), text)
    return text


def _language(node: nodes.literal_block) -> str:
    language = str(node.get("language") or "").lower()
    classes = {str(item).lower() for item in node.get("classes", [])}
    if language:
        return language
    return next((item for item in classes if item in MOONBIT_LANGUAGES), "")


def _fence_mapping(raw: bytes, displayed: str, fence: dict[str, Any]) -> tuple[list[tuple[int, int, int, int]], int] | None:
    """Map display bytes to frozen raw bytes, including quoted/list fences."""
    start, end = fence.get("raw_byte_range", (None, None))
    if not isinstance(start, int) or not isinstance(end, int) or not 0 <= start <= end <= len(raw):
        return None
    raw_lines = raw[start:end].splitlines(keepends=True)
    display_lines = displayed.encode("utf-8").splitlines(keepends=True)
    if len(raw_lines) != len(display_lines):
        # MyST often drops the final newline from a literal node.
        if len(raw_lines) == len(display_lines) + 1 and raw_lines[-1] in {b"\n", b"\r\n"}:
            raw_lines.pop()
        elif len(raw_lines) == len(display_lines) and display_lines and not display_lines[-1].endswith((b"\n", b"\r")):
            pass
        else:
            return None
    segments: list[tuple[int, int, int, int]] = []
    raw_cursor, display_cursor = start, 0
    for raw_line, display_line in zip(raw_lines, display_lines):
        display_content = display_line.rstrip(b"\r\n")
        position = raw_line.find(display_content)
        if position < 0:
            return None
        segments.append((raw_cursor + position, raw_cursor + position + len(display_content), display_cursor, display_cursor + len(display_content)))
        raw_cursor += len(raw_line)
        display_cursor += len(display_line)
    line_range = fence.get("raw_line_range") or [raw.count(b"\n", 0, start) + 1]
    return segments, int(line_range[0])


def _project_occurrences(occurrences: Any, segments: list[tuple[int, int, int, int]]) -> list[Any]:
    projected = []
    for occurrence in occurrences:
        start, end = occurrence.byte_range
        for raw_start, raw_end, display_start, _display_end in segments:
            if raw_start <= start and end <= raw_end:
                projected.append(replace(occurrence, byte_range=(display_start + start - raw_start, display_start + end - raw_start)))
                break
    return projected


def render_literate(app: Any, source: Any, pagename: str, resolve: Any) -> str | None:
    snapshot = app._moonbit_semantic_snapshot
    store = getattr(app.env, VIRTUAL_KEY, {})
    original = store.get(source.source_id)
    if original is None:
        return None
    document = deepcopy(original)
    raw = snapshot.source_text(source)
    raw_bytes = raw.encode("utf-8")
    renderer = SemanticCodeRenderer()
    occurrences = snapshot.occurrences.get(source.source_id, ())
    unused_fences = list(source.metadata.get("literate_fences") or [])
    for node in list(document.findall(nodes.literal_block)):
        if _language(node) not in MOONBIT_LANGUAGES:
            continue
        mapped = None
        matched_fence = None
        for fence in unused_fences:
            candidate = _fence_mapping(raw_bytes, node.astext(), fence)
            if candidate is not None:
                mapped, matched_fence = candidate, fence
                break
        if matched_fence is not None:
            unused_fences.remove(matched_fence)
        if mapped is None:
            LOGGER.warning("MoonBit literate code block failed closed in %s", source.source_id)
            continue
        segments, line = mapped
        html = renderer.render(
            node.astext(),
            _project_occurrences(occurrences, segments),
            resolve,
            base_offset=0,
            start_line=line,
            line_anchors=True,
            source_page=True,
        )
        node.replace_self(nodes.raw("", html, format="html"))
    for image in document.findall(nodes.image):
        uri = str(image.get("uri") or "")
        if not uri.startswith("mbt-asset:"):
            continue
        asset = snapshot.assets.get(uri.removeprefix("mbt-asset:"))
        if asset is None:
            raise ExtensionError(f"literate doctree references unknown asset: {uri}")
        digest = asset.blob_digest.removeprefix("sha256:")
        target = f"_static/moonbit-semantic/assets/{digest}/{asset.path.rsplit('/', 1)[-1]}"
        image["uri"] = relative_uri(app.builder.get_target_uri(pagename), target)
    try:
        return app.builder.render_partial(document)["fragment"]
    except Exception as exc:
        if app.config.moonbit_semantic_required:
            raise
        LOGGER.warning("MoonBit literate source %s could not be rendered: %s", source.source_id, exc)
        return None
