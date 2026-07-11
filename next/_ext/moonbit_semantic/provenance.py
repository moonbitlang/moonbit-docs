"""Portable provenance for code displayed by Sphinx.

The semantic snapshot describes UTF-8 byte ranges in frozen source blobs, but
``literalinclude`` may slice and transform those blobs before they reach a
``literal_block``.  This module records a small, pickle-safe segment map from
the displayed bytes back to the frozen source bytes.  Mapping is deliberately
strict: when the displayed text, source digest, or a range boundary cannot be
verified, callers must keep the ordinary Sphinx code block.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
import codecs
import hashlib
from pathlib import Path, PurePosixPath
import textwrap
from typing import Any, Iterable, Mapping, Sequence

from sphinx.directives.code import parse_line_num_spec

from .snapshot import Occurrence, SemanticSnapshot, Source


PROVENANCE_VERSION = 1


def sha256_text(text: str) -> str:
    return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def normalize_digest(value: str) -> str:
    return value.removeprefix("sha256:").lower()


@dataclass(frozen=True)
class _Unit:
    text: str
    source_start: int | None
    source_end: int | None
    kind: str = "identity"


def _normalized_utf8_units(raw: bytes, *, strip_bom: bool = False) -> list[_Unit]:
    """Decode UTF-8 and reproduce ``open(..., newline=None)`` newlines."""

    bom_size = 3 if strip_bom and raw.startswith(codecs.BOM_UTF8) else 0
    text = raw[bom_size:].decode("utf-8")
    raw_units: list[_Unit] = []
    offset = bom_size
    for character in text:
        size = len(character.encode("utf-8"))
        raw_units.append(_Unit(character, offset, offset + size))
        offset += size

    result: list[_Unit] = []
    index = 0
    while index < len(raw_units):
        unit = raw_units[index]
        if unit.text == "\r":
            if index + 1 < len(raw_units) and raw_units[index + 1].text == "\n":
                following = raw_units[index + 1]
                result.append(
                    _Unit("\n", unit.source_start, following.source_end, "newline-normalized")
                )
                index += 2
                continue
            result.append(_Unit("\n", unit.source_start, unit.source_end, "newline-normalized"))
        else:
            result.append(unit)
        index += 1
    return result


def _expand_tabs(units: Sequence[_Unit], tab_width: int) -> list[_Unit]:
    result: list[_Unit] = []
    column = 0
    for unit in units:
        if unit.text == "\t":
            count = tab_width - (column % tab_width)
            result.extend(
                _Unit(" ", unit.source_start, unit.source_end, "tab-expanded")
                for _ in range(count)
            )
            column += count
        else:
            result.append(unit)
            if unit.text in {"\n", "\r"}:
                column = 0
            else:
                column += 1
    return result


def _split_lines(units: Sequence[_Unit]) -> list[list[_Unit]]:
    text = "".join(unit.text for unit in units)
    parts = text.splitlines(True)
    result: list[list[_Unit]] = []
    offset = 0
    for part in parts:
        length = len(part)
        result.append(list(units[offset : offset + length]))
        offset += length
    if offset != len(units):
        raise ValueError("could not split tracked source into lines")
    return result


def _line_text(line: Sequence[_Unit]) -> str:
    return "".join(unit.text for unit in line)


def _filter_start(lines: list[list[_Unit]], options: Mapping[str, Any]) -> list[list[_Unit]]:
    if options.get("start-at"):
        marker, after = str(options["start-at"]), False
    elif options.get("start-after"):
        marker, after = str(options["start-after"]), True
    else:
        return lines
    for number, line in enumerate(lines):
        if marker in _line_text(line):
            return lines[number + 1 :] if after else lines[number:]
    raise ValueError(f"start marker not found: {marker}")


def _filter_end(lines: list[list[_Unit]], options: Mapping[str, Any]) -> list[list[_Unit]]:
    if options.get("end-at"):
        marker, inclusive = str(options["end-at"]), True
    elif options.get("end-before"):
        marker, inclusive = str(options["end-before"]), False
    else:
        return lines
    for number, line in enumerate(lines):
        if marker in _line_text(line):
            if inclusive:
                return lines[: number + 1]
            # Match Sphinx 8.1: an end-before marker on the first retained line
            # is ignored and searching continues.
            if number != 0:
                return lines[:number]
    raise ValueError(f"end marker not found: {marker}")


def _filter_lines(lines: list[list[_Unit]], options: Mapping[str, Any]) -> list[list[_Unit]]:
    specification = options.get("lines")
    if not specification:
        return lines
    selected = parse_line_num_spec(str(specification), len(lines))
    result = [lines[number] for number in selected if number < len(lines)]
    if not result:
        raise ValueError(f"line specification selected no lines: {specification}")
    return result


def _explicit_dedent(line: list[_Unit], amount: int) -> list[_Unit]:
    result = line[amount:]
    if line and line[-1].text == "\n" and not result:
        result = [line[-1]]
    return [replace(unit, kind="dedented") for unit in result]


def _automatic_dedent(lines: list[list[_Unit]]) -> list[list[_Unit]]:
    expected = textwrap.dedent("".join(_line_text(line) for line in lines)).splitlines(True)
    if len(expected) != len(lines):
        raise ValueError("automatic dedent changed the tracked line count")
    result: list[list[_Unit]] = []
    for original, rendered in zip(lines, expected):
        original_text = _line_text(original)
        if not original_text.endswith(rendered):
            raise ValueError("automatic dedent output is not a source-line suffix")
        removed = len(original_text) - len(rendered)
        retained = original[removed:]
        result.append([replace(unit, kind="dedented") for unit in retained])
    return result


def _filter_dedent(lines: list[list[_Unit]], options: Mapping[str, Any]) -> list[list[_Unit]]:
    if "dedent" not in options:
        return lines
    amount = options.get("dedent")
    if amount is None:
        return _automatic_dedent(lines)
    return [_explicit_dedent(line, int(amount)) for line in lines]


def _synthetic_line(value: Any, kind: str) -> list[_Unit]:
    return [_Unit(character, None, None, kind) for character in str(value) + "\n"]


def _segments(units: Sequence[_Unit]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    display_offset = 0
    for unit in units:
        display_size = len(unit.text.encode("utf-8"))
        candidate = {
            "display": [display_offset, display_offset + display_size],
            "source": (
                [unit.source_start, unit.source_end]
                if unit.source_start is not None and unit.source_end is not None
                else None
            ),
            "kind": unit.kind,
        }
        display_offset += display_size
        if result:
            previous = result[-1]
            same_kind = previous["kind"] == candidate["kind"]
            display_adjacent = previous["display"][1] == candidate["display"][0]
            if previous["source"] is None and candidate["source"] is None:
                merge = same_kind and display_adjacent
            elif previous["source"] is not None and candidate["source"] is not None:
                # Coalesced mapped segments must remain affine so a byte range
                # can be translated without guessing inside a tab or CRLF.
                previous_affine = (
                    previous["display"][1] - previous["display"][0]
                    == previous["source"][1] - previous["source"][0]
                )
                candidate_affine = display_size == candidate["source"][1] - candidate["source"][0]
                merge = (
                    same_kind
                    and display_adjacent
                    and previous_affine
                    and candidate_affine
                    and previous["source"][1] == candidate["source"][0]
                )
            else:
                merge = False
            if merge:
                previous["display"][1] = candidate["display"][1]
                if previous["source"] is not None:
                    previous["source"][1] = candidate["source"][1]
                continue
        result.append(candidate)
    return result


def build_literalinclude_provenance(
    raw: bytes,
    displayed_text: str,
    options: Mapping[str, Any],
    *,
    source_id: str | None,
    target: str,
) -> dict[str, Any]:
    """Build a JSON/pickle-safe map while preserving Sphinx's display text.

    ``diff`` and ``pyobject`` retain all metadata but intentionally do not get
    semantic segments.  Their display semantics require a second source or a
    language-specific parser, respectively, and attaching approximate ranges
    would violate the fail-closed contract.
    """

    portable_options = {
        str(key): value
        for key, value in options.items()
        if isinstance(value, (str, int, bool, type(None), list, tuple))
    }
    result: dict[str, Any] = {
        "version": PROVENANCE_VERSION,
        "source_id": source_id,
        "target": target,
        "source_digest": sha256_bytes(raw),
        "display_digest": sha256_text(displayed_text),
        "options": portable_options,
        "segments": [],
        "valid": False,
    }
    if "diff" in options or "pyobject" in options:
        result["reason"] = "diff/pyobject provenance is intentionally unsupported"
        return result

    encoding = str(options.get("encoding") or "utf-8")
    try:
        canonical_encoding = codecs.lookup(encoding).name
        if canonical_encoding not in {"utf-8", "utf-8-sig"}:
            result["reason"] = f"non-UTF-8 include encoding: {encoding}"
            return result
        units = _normalized_utf8_units(raw, strip_bom=canonical_encoding == "utf-8-sig")
        if "tab-width" in options:
            units = _expand_tabs(units, int(options["tab-width"]))
        lines = _split_lines(units)
        lines = _filter_start(lines, options)
        lines = _filter_end(lines, options)
        lines = _filter_lines(lines, options)
        lines = _filter_dedent(lines, options)
        if options.get("prepend"):
            lines.insert(0, _synthetic_line(options["prepend"], "prepend"))
        if options.get("append"):
            lines.append(_synthetic_line(options["append"], "append"))
        displayed_units = [unit for line in lines for unit in line]
        reproduced = "".join(unit.text for unit in displayed_units)
        if reproduced != displayed_text:
            result["reason"] = "tracked literalinclude output differs from Sphinx output"
            return result
        result["segments"] = _segments(displayed_units)
        result["valid"] = source_id is not None
        if source_id is None:
            result["reason"] = "include target is absent from the semantic snapshot"
        return result
    except (LookupError, UnicodeError, ValueError, TypeError, IndexError) as exc:
        result["reason"] = str(exc)
        return result


def _path_aliases(path: Path, roots: Iterable[Path]) -> set[str]:
    aliases = {path.as_posix().lstrip("/")}
    resolved = path.resolve()
    for root in roots:
        try:
            aliases.add(resolved.relative_to(root.resolve()).as_posix())
        except ValueError:
            pass
    return aliases


def _source_aliases(source: Source) -> set[str]:
    aliases = {PurePosixPath(source.path.replace("\\", "/")).as_posix().lstrip("/")}
    for key in ("aliases", "path_aliases", "portable_aliases"):
        values = source.metadata.get(key, ())
        if isinstance(values, str):
            values = (values,)
        if isinstance(values, Sequence):
            aliases.update(str(value).replace("\\", "/").lstrip("/") for value in values)
    return aliases


def resolve_snapshot_source(
    snapshot: SemanticSnapshot,
    filename: str | Path,
    raw: bytes,
    *,
    roots: Iterable[str | Path] = (),
) -> Source | None:
    """Resolve an include path without publishing or persisting absolute paths."""

    path = Path(filename)
    path_aliases = _path_aliases(path, (Path(root) for root in roots))
    digest = normalize_digest(sha256_bytes(raw))
    exact_matches: list[Source] = []
    suffix_matches: list[Source] = []
    for source in snapshot.sources.values():
        if normalize_digest(source.blob_digest) != digest:
            continue
        source_aliases = _source_aliases(source)
        exact = path_aliases & source_aliases
        suffix = any(
            alias.endswith("/" + source_alias) or source_alias.endswith("/" + alias)
            for alias in path_aliases
            for source_alias in source_aliases
            if alias and source_alias
        )
        if exact:
            exact_matches.append(source)
        elif suffix:
            suffix_matches.append(source)
    if len(exact_matches) == 1:
        return exact_matches[0]
    if exact_matches:
        return None
    return suffix_matches[0] if len(suffix_matches) == 1 else None


def identity_provenance(
    source: Source,
    source_bytes: bytes,
    displayed_text: str,
    source_start: int,
    *,
    target: str,
) -> dict[str, Any]:
    size = len(displayed_text.encode("utf-8"))
    return {
        "version": PROVENANCE_VERSION,
        "source_id": source.source_id,
        "target": target,
        "source_digest": sha256_bytes(source_bytes),
        "display_digest": sha256_text(displayed_text),
        "options": {},
        "segments": [
            {
                "display": [0, size],
                "source": [source_start, source_start + size],
                "kind": "identity",
            }
        ],
        "valid": True,
    }


def infer_identity_provenance(
    snapshot: SemanticSnapshot,
    filename: str | Path,
    displayed_text: str,
    *,
    roots: Iterable[str | Path] = (),
) -> dict[str, Any] | None:
    """Infer provenance for included ``.mbt.md`` fences when it is unambiguous."""

    try:
        raw = Path(filename).read_bytes()
    except OSError:
        return None
    source = resolve_snapshot_source(snapshot, filename, raw, roots=roots)
    if source is None:
        return None
    needle = displayed_text.encode("utf-8")
    first = raw.find(needle)
    if first < 0 or raw.find(needle, first + 1) >= 0:
        return None
    return identity_provenance(source, raw, displayed_text, first, target=source.path)


def provenance_is_current(
    provenance: Mapping[str, Any],
    displayed_text: str,
    snapshot: SemanticSnapshot,
) -> bool:
    if provenance.get("version") != PROVENANCE_VERSION or provenance.get("valid") is not True:
        return False
    if provenance.get("display_digest") != sha256_text(displayed_text):
        return False
    source_id = provenance.get("source_id")
    source = snapshot.sources.get(source_id)
    if source is None:
        return False
    if normalize_digest(str(provenance.get("source_digest") or "")) != normalize_digest(source.blob_digest):
        return False
    try:
        return sha256_bytes(snapshot.blob_bytes(source)) == provenance.get("source_digest")
    except Exception:
        return False


def map_source_range(
    provenance: Mapping[str, Any], source_range: tuple[int, int]
) -> tuple[int, int] | None:
    """Map one exact source range to one contiguous displayed range."""

    source_start, source_end = source_range
    if source_end <= source_start:
        return None
    pieces: list[tuple[int, int, int, int]] = []
    for segment in provenance.get("segments", ()):
        display = segment.get("display")
        source = segment.get("source")
        if not (
            isinstance(display, (list, tuple))
            and len(display) == 2
            and isinstance(source, (list, tuple))
            and len(source) == 2
        ):
            continue
        ds, de = int(display[0]), int(display[1])
        ss, se = int(source[0]), int(source[1])
        if de - ds != se - ss or source_end <= ss or source_start >= se:
            continue
        left, right = max(source_start, ss), min(source_end, se)
        pieces.append((left, right, ds + left - ss, ds + right - ss))
    if not pieces:
        return None
    pieces.sort()
    source_cursor = source_start
    display_cursor: int | None = None
    display_start: int | None = None
    for left, right, shown_left, shown_right in pieces:
        if left != source_cursor:
            return None
        if display_cursor is not None and shown_left != display_cursor:
            return None
        if display_start is None:
            display_start = shown_left
        source_cursor = right
        display_cursor = shown_right
    if source_cursor != source_end or display_start is None or display_cursor is None:
        return None
    return display_start, display_cursor


def map_occurrences(
    provenance: Mapping[str, Any], occurrences: Iterable[Occurrence]
) -> tuple[Occurrence, ...]:
    mapped: list[Occurrence] = []
    for occurrence in occurrences:
        displayed_range = map_source_range(provenance, occurrence.byte_range)
        if displayed_range is not None:
            mapped.append(replace(occurrence, byte_range=displayed_range))
    return tuple(mapped)


def first_source_line(
    provenance: Mapping[str, Any], snapshot: SemanticSnapshot
) -> int | None:
    source = snapshot.sources.get(provenance.get("source_id"))
    if source is None:
        return None
    starts = [
        segment["source"][0]
        for segment in provenance.get("segments", ())
        if isinstance(segment.get("source"), (list, tuple))
    ]
    if not starts:
        return None
    return snapshot.blob_bytes(source).count(b"\n", 0, min(starts)) + 1
