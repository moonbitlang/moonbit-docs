"""Lossless MoonBit fence inventory for ``.mbt.md`` files."""

from __future__ import annotations

import re
from typing import Any

from .canonical import digest_bytes


OPEN = re.compile(rb"^(?P<prefix>[ \t]*(?:>[ \t]*)*)(?P<mark>`{3,}|~{3,})[ \t]*(?P<info>[^\r\n]*)")
MOONBIT_NAMES = {"mbt", "moonbit", "moonbit-check", "moonbit-skip", "moonbit-nocheck", "mbt-check", "mbt-skip", "mbt-nocheck", "mbt-md"}


def extract_literate_fences(raw: bytes) -> list[dict[str, Any]]:
    lines = raw.splitlines(keepends=True)
    offsets: list[int] = []
    total = 0
    for line in lines:
        offsets.append(total)
        total += len(line)
    result: list[dict[str, Any]] = []
    index = 0
    while index < len(lines):
        match = OPEN.match(lines[index])
        if not match:
            index += 1
            continue
        info = match.group("info").decode("utf-8", "replace").strip().lower()
        language = _language(info)
        mark = match.group("mark")
        close = re.compile(rb"^[ \t]*(?:>[ \t]*)*" + re.escape(mark[:1]) + rb"{" + str(len(mark)).encode() + rb",}[ \t]*(?:\r?\n)?$")
        end = index + 1
        while end < len(lines) and not close.match(lines[end]):
            end += 1
        if end >= len(lines):
            index += 1
            continue
        if language in MOONBIT_NAMES:
            start_byte = offsets[index + 1] if index + 1 < len(offsets) else total
            end_byte = offsets[end]
            content = raw[start_byte:end_byte]
            status = "display-only" if ("skip" in language or "nocheck" in language) else "analyzed"
            result.append({
                "raw_byte_range": [start_byte, end_byte],
                "raw_line_range": [index + 2, end + 1],
                "content_digest": digest_bytes(content),
                "fence_kind": language,
                "semantic_status": status,
                "range_map": [{
                    "raw_utf8": [start_byte, end_byte],
                    "display_utf8": [0, len(content)],
                    "transform_kind": "identity",
                }],
            })
        index = end + 1
    return result


def moonbit_projection(raw: bytes, fences: list[dict[str, Any]]) -> bytes:
    projected = bytearray(raw)
    keep = bytearray(len(raw))
    for fence in fences:
        if fence["semantic_status"] == "analyzed":
            start, end = fence["raw_byte_range"]
            keep[start:end] = b"\1" * (end - start)
    for index, value in enumerate(projected):
        if not keep[index] and value not in (10, 13):
            projected[index] = 32
    return bytes(projected)


def _language(info: str) -> str:
    if info.startswith("{") and "}" in info:
        info = info[1 : info.index("}")]
    words = info.split()
    if not words:
        return ""
    if len(words) > 1 and words[0] in {"mbt", "moonbit"} and words[1] in {"check", "skip", "nocheck"}:
        return f"{words[0]}-{words[1]}"
    return words[0]
