"""Coordinate conversion on immutable UTF-8 source blobs."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


class RangeError(ValueError):
    pass


@dataclass(frozen=True)
class SourceCoordinates:
    raw: bytes

    def __post_init__(self) -> None:
        try:
            text = self.raw.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise RangeError("source is not valid UTF-8") from exc
        object.__setattr__(self, "text", text)
        byte_starts = [0]
        total = 0
        for line in text.splitlines(keepends=True):
            total += len(line.encode("utf-8"))
            byte_starts.append(total)
        if not text or (not text.endswith("\n") and byte_starts[-1] != len(self.raw)):
            byte_starts.append(len(self.raw))
        object.__setattr__(self, "line_byte_starts", tuple(byte_starts))

    def position_to_byte(self, position: dict[str, int], encoding: str = "utf-16") -> int:
        line = position.get("line")
        char = position.get("character")
        if not isinstance(line, int) or not isinstance(char, int) or line < 0 or char < 0:
            raise RangeError(f"invalid LSP position: {position!r}")
        lines = self.text.splitlines(keepends=True)
        if line >= len(lines):
            if not self.text and line == 0 and char == 0:
                return 0
            if line == len(lines) and char == 0 and self.text.endswith("\n"):
                return len(self.raw)
            raise RangeError(f"line out of range: {line}")
        content = lines[line]
        if content.endswith("\n"):
            content = content[:-1]
            if content.endswith("\r"):
                content = content[:-1]
        prefix = _prefix_for_units(content, char, encoding)
        return self.line_byte_starts[line] + len(prefix.encode("utf-8"))

    def range_to_bytes(self, value: dict[str, Any], encoding: str = "utf-16") -> list[int]:
        try:
            start = self.position_to_byte(value["start"], encoding)
            end = self.position_to_byte(value["end"], encoding)
        except (KeyError, TypeError) as exc:
            raise RangeError(f"invalid LSP range: {value!r}") from exc
        if end < start:
            raise RangeError("range end precedes start")
        return [start, end]

    def byte_to_position(self, offset: int, encoding: str = "utf-16") -> dict[str, int]:
        if offset < 0 or offset > len(self.raw):
            raise RangeError(f"byte offset out of range: {offset}")
        prefix = self.raw[:offset]
        try:
            decoded = prefix.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise RangeError("offset splits a UTF-8 code point") from exc
        line = decoded.count("\n")
        tail = decoded.rsplit("\n", 1)[-1]
        return {"line": line, "character": _units(tail, encoding)}


def _units(text: str, encoding: str) -> int:
    if encoding == "utf-8":
        return len(text.encode("utf-8"))
    if encoding == "utf-32":
        return len(text)
    if encoding != "utf-16":
        raise RangeError(f"unsupported position encoding: {encoding}")
    return len(text.encode("utf-16-le")) // 2


def _prefix_for_units(text: str, count: int, encoding: str) -> str:
    if count == 0:
        return ""
    used = 0
    for index, char in enumerate(text):
        used += _units(char, encoding)
        if used == count:
            return text[: index + 1]
        if used > count:
            raise RangeError("position splits a code point")
    if used == count:
        return text
    raise RangeError(f"character out of range: {count}")
