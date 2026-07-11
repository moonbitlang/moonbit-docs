"""Semantic range overlay renderer shared by docs and source pages."""

from __future__ import annotations

from dataclasses import replace
from html import escape
import re
from typing import Callable, Iterable

from pygments.formatters.html import HtmlFormatter
from sphinx.highlighting import lexer_classes

from .routing import symbol_anchor
from .snapshot import Occurrence


TargetResolver = Callable[[Occurrence], str | None]


def _byte_to_char_boundaries(text: str) -> dict[int, int]:
    result = {0: 0}
    byte_offset = 0
    for char_offset, char in enumerate(text, 1):
        byte_offset += len(char.encode("utf-8"))
        result[byte_offset] = char_offset
    return result


def _char_to_byte_boundaries(text: str) -> list[int]:
    result = [0]
    offset = 0
    for char in text:
        offset += len(char.encode("utf-8"))
        result.append(offset)
    return result


def _semantic_class(occurrence: Occurrence) -> str:
    classes = ["mbt-semantic-token"]
    if occurrence.role == "definition":
        classes.append("mbt-definition")
    if occurrence.hover_id:
        classes.append("mbt-has-hover")
    return " ".join(classes)


def _wrap(text: str, occurrence: Occurrence, href: str | None, lexical_class: str = "") -> str:
    classes = " ".join(item for item in (_semantic_class(occurrence), lexical_class) if item)
    attrs = [f'class="{classes}"']
    if occurrence.hover_id:
        attrs.extend(
            (
                f'data-mbt-hover="{escape(occurrence.hover_id, quote=True)}"',
                'tabindex="0"',
                'aria-haspopup="dialog"',
                'aria-expanded="false"',
            )
        )
    if occurrence.symbol_id:
        attrs.append(f'data-mbt-symbol="{escape(occurrence.symbol_id, quote=True)}"')
    rendered = escape(text)
    if href:
        attrs.append(f'href="{escape(href, quote=True)}"')
        rendered = f"<a {' '.join(attrs)}>{rendered}</a>"
    else:
        rendered = f"<span {' '.join(attrs)}>{rendered}</span>"
    if occurrence.role == "definition" and occurrence.symbol_id:
        rendered = f'<span id="{symbol_anchor(occurrence.symbol_id)}" class="mbt-definition-anchor"></span>{rendered}'
    return rendered


class SemanticCodeRenderer:
    """Render semantic spans without changing the code's ``textContent``.

    Ranges are UTF-8 byte offsets into the exact frozen source blob.  Crossing
    ranges are rejected by selecting the narrowest deterministic range for a
    segment; token-oriented LSP data should normally be disjoint.
    """

    def render(
        self,
        text: str,
        occurrences: Iterable[Occurrence],
        resolve_target: TargetResolver,
        *,
        base_offset: int = 0,
        start_line: int = 1,
        line_anchors: bool = True,
        source_page: bool = False,
        language: str = "moonbit",
    ) -> str:
        encoded_size = len(text.encode("utf-8"))
        local: list[Occurrence] = []
        for item in occurrences:
            start, end = item.byte_range
            if end <= base_offset or start >= base_offset + encoded_size or start == end:
                continue
            clipped = (max(start, base_offset) - base_offset, min(end, base_offset + encoded_size) - base_offset)
            local.append(replace(item, byte_range=clipped))

        boundaries = _byte_to_char_boundaries(text)
        char_boundaries = _char_to_byte_boundaries(text)
        valid: list[Occurrence] = []
        for item in local:
            if item.byte_range[0] in boundaries and item.byte_range[1] in boundaries:
                valid.append(item)
        events = {0, encoded_size}
        for item in valid:
            events.update(item.byte_range)
        for match in re.finditer("\n", text):
            events.add(len(text[: match.start() + 1].encode("utf-8")))
        lexical: list[tuple[int, int, str]] = []
        lexer = lexer_classes.get(language) or lexer_classes.get("mbt")
        if lexer is not None:
            lexer = lexer() if isinstance(lexer, type) else lexer
            formatter = HtmlFormatter()
            for char_start, token_type, value in lexer.get_tokens_unprocessed(text):
                if char_start < 0 or char_start > len(text):
                    continue
                cursor = char_boundaries[char_start]
                char_end = min(char_start + len(value), len(text))
                end = char_boundaries[char_end]
                if cursor >= encoded_size or cursor not in boundaries or end not in boundaries:
                    continue
                css_class = formatter._get_css_class(token_type)
                lexical.append((cursor, end, css_class))
                events.update((cursor, end))
        points = sorted(events)

        chunks: list[str] = []
        line = start_line
        at_line_start = True
        ordered_occurrences = sorted(valid, key=lambda item: (item.byte_range[0], item.byte_range[1]))
        occurrence_index = 0
        active_occurrences: list[Occurrence] = []
        lexical_index = 0
        for left, right in zip(points, points[1:]):
            if at_line_start and line_anchors:
                chunks.append(f'<span id="L{line}" class="mbt-line-anchor" data-source-line="{line}"></span>')
                at_line_start = False
            piece = text[boundaries[left] : boundaries[right]]
            active_occurrences = [item for item in active_occurrences if item.byte_range[1] > left]
            while occurrence_index < len(ordered_occurrences) and ordered_occurrences[occurrence_index].byte_range[0] <= left:
                item = ordered_occurrences[occurrence_index]
                if item.byte_range[1] > left:
                    active_occurrences.append(item)
                occurrence_index += 1
            covering = [item for item in active_occurrences if right <= item.byte_range[1]]
            occurrence = min(
                covering,
                key=lambda item: (item.byte_range[1] - item.byte_range[0], item.role != "definition", item.symbol_id or ""),
                default=None,
            )
            while lexical_index < len(lexical) and lexical[lexical_index][1] <= left:
                lexical_index += 1
            lexical_class = ""
            if lexical_index < len(lexical):
                lexical_start, lexical_end, lexical_css = lexical[lexical_index]
                if lexical_start <= left and right <= lexical_end:
                    lexical_class = lexical_css
            if occurrence:
                chunks.append(_wrap(piece, occurrence, resolve_target(occurrence), lexical_class))
            elif lexical_class:
                chunks.append(f'<span class="{lexical_class}">{escape(piece)}</span>')
            else:
                chunks.append(escape(piece))
            newline_count = piece.count("\n")
            if newline_count:
                line += newline_count
                at_line_start = piece.endswith("\n")
        if not points or (text == ""):
            if line_anchors:
                chunks.append(f'<span id="L{line}" class="mbt-line-anchor" data-source-line="{line}"></span>')
        classes = "mbt-semantic-source" if source_page else "mbt-semantic-code"
        marker = ' data-mbt-semantic-source="true"' if source_page else ""
        return (
            f'<div class="{classes}"{marker}><div class="highlight-moonbit notranslate">'
            f'<div class="highlight"><pre>{"".join(chunks)}</pre></div></div></div>'
        )
