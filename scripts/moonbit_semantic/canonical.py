"""Deterministic serialization, hashing, and portable path identities."""

from __future__ import annotations

import hashlib
import json
import os
import unicodedata
from pathlib import Path
from typing import Any, Iterable


def canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()


def digest_bytes(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def digest_json(value: Any) -> str:
    return digest_bytes(canonical_json_bytes(value))


def normalize_relative(path: str | Path) -> str:
    value = unicodedata.normalize("NFC", Path(path).as_posix())
    if value.startswith("/") or value == ".." or value.startswith("../"):
        raise ValueError(f"path is not relative: {path}")
    parts = [part for part in value.split("/") if part not in ("", ".")]
    if any(part == ".." for part in parts):
        raise ValueError(f"path escapes its root: {path}")
    return "/".join(parts)


def realpath(path: Path) -> Path:
    return Path(os.path.realpath(path))


def is_within(path: Path, root: Path) -> bool:
    try:
        realpath(path).relative_to(realpath(root))
        return True
    except ValueError:
        return False


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(canonical_json_bytes(value))


def write_jsonl(path: Path, values: Iterable[dict[str, Any]], key) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    ordered = sorted(values, key=key)
    path.write_bytes(b"".join(canonical_json_bytes(item) for item in ordered))
