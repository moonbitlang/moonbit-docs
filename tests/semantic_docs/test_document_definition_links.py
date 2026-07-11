from __future__ import annotations

import hashlib
from io import StringIO
import json
from pathlib import Path
import re
import sys
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[2]
EXT = ROOT / "next" / "_ext"
if str(EXT) not in sys.path:
    sys.path.insert(0, str(EXT))

from moonbit_semantic.links import (  # noqa: E402
    DEFINITION_STORE_ATTRIBUTE,
    merge_document_definitions,
    purge_document_definitions,
)


EXTERNAL_URL = (
    "https://mooncakes.io/docs/moonbitlang/core/cmp#maximum"
)


def _ranges(raw: bytes, value: bytes) -> list[list[int]]:
    result = []
    start = 0
    while (found := raw.find(value, start)) >= 0:
        result.append([found, found + len(value)])
        start = found + len(value)
    return result


def _write_snapshot(root: Path, sources: dict[str, bytes]) -> Path:
    snapshot = root / "snapshot"
    blobs = snapshot / "blobs" / "sha256"
    blobs.mkdir(parents=True)
    source_ids = {
        "defs.mbt": "local:code/defs.mbt",
        "hidden.mbt": "local:code/hidden.mbt",
        "use.mbt": "local:code/use.mbt",
        "cmp.mbt": "stdlib:moonbitlang/core@toolchain:cmp/cmp.mbt",
    }
    source_records = []
    for path, raw in sources.items():
        digest = hashlib.sha256(raw).hexdigest()
        (blobs / digest).write_bytes(raw)
        origin = "stdlib" if path == "cmp.mbt" else "local"
        logical_path = "cmp/cmp.mbt" if path == "cmp.mbt" else f"code/{path}"
        source_records.append(
            {
                "source_id": source_ids[path],
                "path": logical_path,
                "blob_digest": f"sha256:{digest}",
                "kind": "mbt",
                "origin": origin,
                "module": "moonbitlang/core" if origin == "stdlib" else "demo",
                "version": "toolchain" if origin == "stdlib" else "",
                "package": "moonbitlang/core/cmp" if origin == "stdlib" else "demo",
                "analysis_status": (
                    "deferred-by-origin-policy" if origin == "stdlib" else "required"
                ),
                "route_key": f"test/{path}",
            }
        )

    defs = sources["defs.mbt"]
    hidden = sources["hidden.mbt"]
    uses = sources["use.mbt"]
    cmp_source = sources["cmp.mbt"]
    answer_range, other_range = (
        _ranges(defs, name)[0] for name in (b"answer", b"other")
    )
    hidden_range = _ranges(hidden, b"hidden")[0]
    maximum_range = _ranges(cmp_source, b"maximum")[0]
    symbols = [
        {
            "symbol_id": symbol_id,
            "source_id": source_id,
            "selection_range_utf8": byte_range,
            "name": name,
            "kind": "function",
            "package": "demo",
        }
        for symbol_id, source_id, byte_range, name in (
            ("sym:answer", source_ids["defs.mbt"], answer_range, "answer"),
            ("sym:other", source_ids["defs.mbt"], other_range, "other"),
            ("sym:hidden", source_ids["hidden.mbt"], hidden_range, "hidden"),
        )
    ]

    def local_target(
        source: str, symbol: str, byte_range: list[int]
    ) -> dict[str, object]:
        return {
            "target_source_id": source,
            "target_selection_range_utf8": byte_range,
            "target_range_utf8": byte_range,
            "symbol_id": symbol,
        }

    external_target = {
        "target_source_id": source_ids["cmp.mbt"],
        "target_selection_range_utf8": maximum_range,
        "target_range_utf8": maximum_range,
        "external_target_id": "mooncakes:core-maximum",
        "external_status": "exact",
    }
    use_ranges = {
        name.decode(): _ranges(uses, name)[0]
        for name in (
            b"answer",
            b"hidden",
            b"maximum",
            b"maximum_alias",
            b"mixed",
            b"ambiguous",
        )
    }
    definitions = {
        "answer": [
            local_target(source_ids["defs.mbt"], "sym:answer", answer_range)
        ],
        "hidden": [
            local_target(source_ids["hidden.mbt"], "sym:hidden", hidden_range)
        ],
        "maximum": [external_target],
        "maximum_alias": [dict(external_target), dict(external_target)],
        "mixed": [
            dict(external_target),
            local_target(source_ids["hidden.mbt"], "sym:hidden", hidden_range),
        ],
        "ambiguous": [
            local_target(source_ids["defs.mbt"], "sym:answer", answer_range),
            local_target(source_ids["defs.mbt"], "sym:other", other_range),
        ],
    }
    occurrences = [
        {
            "source_id": source_ids["use.mbt"],
            "effective_range_utf8": byte_range,
            "candidate_range_utf8": byte_range,
            "definitions": definitions[name],
        }
        for name, byte_range in use_ranges.items()
    ]

    (snapshot / "sources.jsonl").write_text(
        "".join(json.dumps(record) + "\n" for record in source_records),
        encoding="utf-8",
    )
    (snapshot / "symbols.jsonl").write_text(
        "".join(json.dumps(record) + "\n" for record in symbols),
        encoding="utf-8",
    )
    (snapshot / "occurrences.jsonl").write_text(
        "".join(json.dumps(record) + "\n" for record in occurrences),
        encoding="utf-8",
    )
    (snapshot / "external-targets.jsonl").write_text(
        json.dumps(
            {
                "external_target_id": "mooncakes:core-maximum",
                "provider": "mooncakes",
                "module": "moonbitlang/core",
                "requested_version": "toolchain",
                "resolved_version": "0.1.20260622+a46be2066",
                "package": "moonbitlang/core/cmp",
                "anchor": "maximum",
                "url": EXTERNAL_URL,
                "match": "location",
                "status": "exact",
            }
        )
        + "\n",
        encoding="utf-8",
    )
    files = []
    for path in sorted(snapshot.rglob("*")):
        if path.is_file() and path.name != "manifest.json":
            raw = path.read_bytes()
            files.append(
                {
                    "path": path.relative_to(snapshot).as_posix(),
                    "digest": "sha256:" + hashlib.sha256(raw).hexdigest(),
                    "size": len(raw),
                }
            )
    (snapshot / "manifest.json").write_text(
        json.dumps(
            {
                "schema": "moonbit-semantic-snapshot/v1",
                "corpus_digest": "sha256:test",
                "files": files,
            }
        ),
        encoding="utf-8",
    )
    return snapshot


def _literalinclude(path: str) -> str:
    return (
        f"```{{literalinclude}} code/{path}\n"
        ":language: moonbit\n"
        "```\n"
    )


def _project(tmp_path: Path, *, parallel: int = 2):
    from sphinx.application import Sphinx

    docs = tmp_path / "docs"
    out = tmp_path / "out"
    doctrees = tmp_path / "doctrees"
    code = docs / "code"
    code.mkdir(parents=True)
    sources = {
        "defs.mbt": (
            b"pub fn answer() -> Int { 42 }\n"
            b"pub fn other() -> Int { 7 }\n"
        ),
        "hidden.mbt": b"pub fn hidden() -> Int { 0 }\n",
        "use.mbt": (
            b"fn use() {\n"
            b"  answer()\n"
            b"  hidden()\n"
            b"  maximum()\n"
            b"  maximum_alias()\n"
            b"  mixed()\n"
            b"  ambiguous()\n"
            b"}\n"
        ),
        "cmp.mbt": b"pub fn maximum() -> Int { 2 }\n",
    }
    for name, raw in sources.items():
        if name != "cmp.mbt":
            (code / name).write_bytes(raw)
    snapshot = _write_snapshot(tmp_path, sources)
    (docs / "conf.py").write_text(
        "\n".join(
            (
                "import sys",
                f"sys.path.insert(0, {str(EXT)!r})",
                "extensions = ['myst_parser', 'moonbit_semantic']",
                "source_suffix = {'.md': 'markdown'}",
                "master_doc = 'index'",
                "project = 'document-link-test'",
                "html_theme = 'basic'",
                f"moonbit_semantic_snapshot = {str(snapshot)!r}",
                "moonbit_semantic_required = True",
            )
        ),
        encoding="utf-8",
    )
    (docs / "index.md").write_text(
        "# Index\n\n```{toctree}\n:hidden:\n\na\nb\nc\n```\n",
        encoding="utf-8",
    )
    (docs / "a.md").write_text(
        "# A\n\n" + _literalinclude("defs.mbt") + _literalinclude("defs.mbt"),
        encoding="utf-8",
    )
    (docs / "b.md").write_text(
        "# B\n\n" + _literalinclude("use.mbt"), encoding="utf-8"
    )
    (docs / "c.md").write_text(
        "# C\n\n" + _literalinclude("defs.mbt"), encoding="utf-8"
    )
    status, warning = StringIO(), StringIO()
    app = Sphinx(
        docs,
        docs,
        out,
        doctrees,
        "html",
        status=status,
        warning=warning,
        freshenv=True,
        parallel=parallel,
    )
    return app, out, warning


def _tag_for(html: str, name: str) -> tuple[str, str | None]:
    match = re.search(
        rf'<(?P<tag>a|span) (?P<attrs>[^>]*)>{re.escape(name)}</(?P=tag)>',
        html,
    )
    assert match is not None, name
    href = re.search(r'href="([^"]+)"', match.group("attrs"))
    return match.group("tag"), href.group(1) if href else None


def test_document_and_external_definition_routes_are_fail_closed(
    tmp_path: Path,
) -> None:
    app, out, warning = _project(tmp_path, parallel=2)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()
    assert not (out / "_moonbit-src").exists()
    assert not (out / "_moonbit-source").exists()

    a_html = (out / "a.html").read_text(encoding="utf-8")
    b_html = (out / "b.html").read_text(encoding="utf-8")
    anchors = re.findall(r'id="(mb-def-doc-[^"]+)"', a_html)
    assert len(anchors) == 4
    assert len(set(anchors)) == len(anchors)

    answer_tag, answer_href = _tag_for(b_html, "answer")
    assert answer_tag == "a"
    assert answer_href is not None
    assert answer_href.startswith("a.html#mb-def-doc-0-")
    assert answer_href.split("#", 1)[1] in anchors

    assert _tag_for(b_html, "hidden") == ("span", None)
    assert _tag_for(b_html, "maximum") == ("a", EXTERNAL_URL)
    assert _tag_for(b_html, "maximum_alias") == ("a", EXTERNAL_URL)
    assert _tag_for(b_html, "mixed") == ("span", None)
    assert _tag_for(b_html, "ambiguous") == ("span", None)


def test_document_destination_store_purges_and_merges_by_docname() -> None:
    key = ("local:defs.mbt", "sym:answer", 4, 10)
    env = SimpleNamespace(
        moonbit_semantic_document_definitions={
            "keep": {key: [(0, "keep-anchor")]},
            "stale": {key: [(1, "stale-anchor")]},
        }
    )
    other = SimpleNamespace(
        moonbit_semantic_document_definitions={
            "worker": {key: [(2, "worker-anchor")]}
        }
    )

    purge_document_definitions(env, "stale")
    merge_document_definitions(env, ["worker"], other)

    store = getattr(env, DEFINITION_STORE_ATTRIBUTE)
    assert set(store) == {"keep", "worker"}
    assert store["worker"][key] == [(2, "worker-anchor")]
