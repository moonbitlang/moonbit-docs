"""Semantic range overlay renderer for MoonBit document code blocks."""

from __future__ import annotations

from html import escape
from typing import Callable, Iterable

from pygments.formatters.html import HtmlFormatter
from sphinx.highlighting import lexer_classes

from .snapshot import Occurrence


TargetResolver = Callable[[Occurrence], str | None]
DefinitionAnchorResolver = Callable[[Occurrence], str | None]


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


def _wrap(
    text: str,
    occurrence: Occurrence,
    href: str | None,
    lexical_class: str = "",
    definition_anchor: str | None = None,
) -> str:
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
    if definition_anchor:
        rendered = f'<span id="{escape(definition_anchor, quote=True)}" class="mbt-definition-anchor"></span>{rendered}'
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
        language: str = "moonbit",
        resolve_definition_anchor: DefinitionAnchorResolver | None = None,
    ) -> str:
        encoded_size = len(text.encode("utf-8"))
        boundaries = _byte_to_char_boundaries(text)
        char_boundaries = _char_to_byte_boundaries(text)
        valid: list[Occurrence] = []
        for item in occurrences:
            start, end = item.byte_range
            if (
                0 <= start < end <= encoded_size
                and start in boundaries
                and end in boundaries
            ):
                valid.append(item)
        events = {0, encoded_size}
        for item in valid:
            events.update(item.byte_range)
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
        ordered_occurrences = sorted(valid, key=lambda item: (item.byte_range[0], item.byte_range[1]))
        occurrence_index = 0
        active_occurrences: list[Occurrence] = []
        lexical_index = 0
        emitted_anchors: set[str] = set()
        for left, right in zip(points, points[1:]):
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
                anchor = None
                if occurrence.role == "definition" and occurrence.symbol_id:
                    candidate = (
                        resolve_definition_anchor(occurrence)
                        if resolve_definition_anchor is not None
                        else None
                    )
                    if candidate and candidate not in emitted_anchors:
                        anchor = candidate
                        emitted_anchors.add(candidate)
                chunks.append(
                    _wrap(
                        piece,
                        occurrence,
                        resolve_target(occurrence),
                        lexical_class,
                        anchor,
                    )
                )
            elif lexical_class:
                chunks.append(f'<span class="{lexical_class}">{escape(piece)}</span>')
            else:
                chunks.append(escape(piece))
        return (
            '<div class="mbt-semantic-code"><div class="highlight-moonbit notranslate">'
            f'<div class="highlight"><pre>{"".join(chunks)}</pre></div></div></div>'
        )
