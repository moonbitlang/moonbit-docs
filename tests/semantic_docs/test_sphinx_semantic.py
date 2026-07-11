from __future__ import annotations

import hashlib
from io import StringIO
import json
from pathlib import Path
import sys
from types import SimpleNamespace

import pytest


ROOT = Path(__file__).resolve().parents[2]
EXT = ROOT / "next" / "_ext"
sys.path.insert(0, str(EXT))

from moonbit_semantic.render import SemanticCodeRenderer
from moonbit_semantic.snapshot import Occurrence, SnapshotError, load_snapshot
from moonbit_semantic.source_pages import get_outdated


def _write_snapshot(
    root: Path,
    *,
    extra_literate: str = "",
    deferred_external_target: bool = False,
) -> Path:
    snapshot = root / "snapshot"
    blobs = snapshot / "blobs" / "sha256"
    occurrences = snapshot / "occurrences" / "ctx"
    hovers = snapshot / "hovers"
    blobs.mkdir(parents=True)
    occurrences.mkdir(parents=True)
    hovers.mkdir(parents=True)

    pure = "pub fn answer() -> Int { 42 }\n"
    literate = "# Literate Guide\n\nProse survives from the frozen Markdown.\n\n```mbt\npub fn lit() -> Int { 7 }\n```\n\n![Frozen logo](logo.svg)\n" + extra_literate
    logo = b'<svg xmlns="http://www.w3.org/2000/svg"><title>logo</title></svg>'
    pure_digest = hashlib.sha256(pure.encode()).hexdigest()
    lit_digest = hashlib.sha256(literate.encode()).hexdigest()
    logo_digest = hashlib.sha256(logo).hexdigest()
    (blobs / pure_digest).write_text(pure)
    (blobs / lit_digest).write_text(literate)
    (blobs / logo_digest).write_bytes(logo)

    sources = [
        {
            "source_id": "local:src/main.mbt",
            "path": "src/main.mbt",
            "blob_digest": f"sha256:{pure_digest}",
            "kind": ".mbt",
            "origin": "local",
            "package": "demo",
            "route_key": "local/demo/src/main.mbt",
        },
        {
            "source_id": "dependency:demo@1.0:guide.mbt.md",
            "path": "guide.mbt.md",
            "blob_digest": f"sha256:{lit_digest}",
            "kind": ".mbt.md",
            "origin": "dependency",
            "module": "demo",
            "version": "1.0",
            "package": "demo/guide",
            "route_key": "pkg/demo/1.0/guide.mbt.md",
        },
    ]
    answer_start = pure.encode().index(b"answer")
    lit_start = literate.encode().index(b"lit()")
    fence_start = literate.encode().index(b"pub fn lit")
    fence_end = literate.encode().index(b"```", fence_start)
    sources[1]["literate_fences"] = [
        {
            "raw_byte_range": [fence_start, fence_end],
            "raw_line_range": [6, 7],
            "content_digest": "sha256:test",
            "fence_kind": "mbt",
            "semantic_status": "analyzed",
            "range_map": [
                {
                    "raw_utf8": [fence_start, fence_end],
                    "display_utf8": [0, fence_end - fence_start],
                    "transform_kind": "identity",
                }
            ],
        }
    ]
    symbols = [
        {
            "symbol_id": "sym:demo.answer",
            "source_id": "local:src/main.mbt",
            "selection_range_utf8": [answer_start, answer_start + len(b"answer")],
            "name": "answer",
            "qualified_name": "demo.answer",
            "kind": "function",
            "package": "demo",
            "hover_id": "hover:answer",
        },
        {
            "symbol_id": "sym:demo.lit",
            "source_id": "dependency:demo@1.0:guide.mbt.md",
            "selection_range_utf8": [lit_start, lit_start + len(b"lit")],
            "name": "lit",
            "kind": "function",
            "package": "demo/guide",
            "hover_id": "hover:lit",
        },
    ]
    if deferred_external_target:
        sources[1]["analysis_status"] = "deferred-by-origin-policy"
        symbols[1].pop("hover_id")
    (snapshot / "sources.jsonl").write_text("".join(json.dumps(item) + "\n" for item in sources))
    (snapshot / "symbols.jsonl").write_text("".join(json.dumps(item) + "\n" for item in symbols))
    (snapshot / "assets.jsonl").write_text(
        json.dumps(
            {
                "asset_id": "asset:logo",
                "owner_source_id": "dependency:demo@1.0:guide.mbt.md",
                "path": "logo.svg",
                "blob_digest": f"sha256:{logo_digest}",
                "mime": "image/svg+xml",
            }
        )
        + "\n"
    )
    occurrence_records = []
    if deferred_external_target:
        occurrence_records.append({
            "source_id": "local:src/main.mbt",
            "context_id": "ctx:local",
            "effective_range_utf8": [answer_start, answer_start + len(b"answer")],
            "candidate_range_utf8": [answer_start, answer_start + len(b"answer")],
            "symbol_id": "sym:demo.answer",
            "hover_id": "hover:answer",
            "definitions": [{
                "target_source_id": "dependency:demo@1.0:guide.mbt.md",
                "target_selection_range_utf8": [lit_start, lit_start + len(b"lit")],
                "target_range_utf8": [lit_start, lit_start + len(b"lit")],
                "symbol_id": "sym:demo.lit",
            }],
        })
    (occurrences / "main.json").write_text(
        json.dumps({"occurrences": occurrence_records})
    )
    (hovers / "all.json").write_text(
        json.dumps(
            {
                "hover:answer": "fn answer() -> Int",
                "hover:lit": "fn lit() -> Int\u2028line separator\u2029paragraph separator",
            }
        )
    )
    files = []
    for path in sorted(snapshot.rglob("*")):
        if path.is_file() and path.name != "manifest.json":
            data = path.read_bytes()
            files.append(
                {
                    "path": path.relative_to(snapshot).as_posix(),
                    "digest": "sha256:" + hashlib.sha256(data).hexdigest(),
                    "size": len(data),
                }
            )
    (snapshot / "manifest.json").write_text(
        json.dumps({"schema": "moonbit-semantic-snapshot/v1", "corpus_digest": "sha256:test", "files": files})
    )
    return snapshot


def _project(tmp_path: Path, snapshot: Path | None, *, required: bool, builder: str = "html", parallel: int = 1):
    from sphinx.application import Sphinx

    src = tmp_path / "docs"
    out = tmp_path / "out"
    doctrees = tmp_path / "doctrees"
    src.mkdir(parents=True)
    configured = repr(str(snapshot)) if snapshot else "None"
    (src / "conf.py").write_text(
        "\n".join(
            [
                "import sys",
                f"sys.path.insert(0, {str(EXT)!r})",
                "extensions = ['myst_parser', 'lexer', 'moonbit_semantic']",
                "source_suffix = {'.md': 'markdown'}",
                "master_doc = 'index'",
                "project = 'semantic-test'",
                "html_theme = 'basic'",
                f"moonbit_semantic_snapshot = {configured}",
                f"moonbit_semantic_required = {required!r}",
                "moonbit_semantic_source_prefix = '_moonbit-src'",
            ]
        )
    )
    (src / "index.md").write_text("# Test docs\n\nOrdinary docs remain available.\n")
    (src / "second.md").write_text("# Second page\n\nParallel read fixture.\n")
    status, warning = StringIO(), StringIO()
    app = Sphinx(src, src, out, doctrees, builder, status=status, warning=warning, freshenv=True, parallel=parallel)
    return app, out, status, warning


def test_snapshot_loader_and_renderer_use_utf8_byte_ranges(tmp_path: Path) -> None:
    snapshot = load_snapshot(_write_snapshot(tmp_path))
    text = "😀answer\n"
    start = len("😀".encode())
    occurrence = Occurrence("source", (start, start + 6), hover_id="hover:answer")
    html = SemanticCodeRenderer().render(text, [occurrence], lambda _item: "target.html", source_page=True)
    assert "😀" in html
    assert 'data-mbt-hover="hover:answer"' in html
    assert 'href="target.html"' in html
    assert 'id="L1"' in html


def test_snapshot_rejects_blob_digest_mismatch(tmp_path: Path) -> None:
    path = _write_snapshot(tmp_path)
    source = json.loads((path / "sources.jsonl").read_text().splitlines()[0])
    blob = path / "blobs" / "sha256" / source["blob_digest"].removeprefix("sha256:")
    blob.write_text("changed")
    with pytest.raises(SnapshotError, match="digest mismatch"):
        load_snapshot(path)


def test_snapshot_change_outdates_every_document_page() -> None:
    app = SimpleNamespace(
        _moonbit_semantic_snapshot=SimpleNamespace(corpus_digest="sha256:new"),
        config=SimpleNamespace(root_doc="index"),
    )
    env = SimpleNamespace(
        moonbit_semantic_corpus_digest="sha256:old",
        found_docs={"second", "index"},
    )

    outdated = get_outdated(app, env, set(), set(), set())

    assert outdated == ["index", "second"]
    assert env.moonbit_semantic_corpus_digest == "sha256:new"


def test_sphinx_generates_code_and_literate_source_pages(tmp_path: Path) -> None:
    snapshot = _write_snapshot(tmp_path)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()

    pure = out / "_moonbit-src" / "local" / "demo" / "src" / "main.mbt.html"
    literate = out / "_moonbit-src" / "pkg" / "demo" / "1.0" / "guide.mbt.md.html"
    assert pure.is_file()
    assert literate.is_file()
    pure_html = pure.read_text()
    lit_html = literate.read_text()
    assert 'data-mbt-semantic-source="true"' in pure_html
    assert 'data-mbt-hover="hover:answer"' in pure_html
    assert "mbt-semantic-token mbt-definition mbt-has-hover nf" in pure_html
    assert 'id="L1"' in pure_html
    assert "mb-def-" in pure_html
    assert "Literate Guide" in lit_html
    assert "Prose survives from the frozen Markdown." in lit_html
    assert 'data-mbt-hover="hover:lit"' in lit_html
    assert "moonbit-semantic/assets/" in lit_html
    assert "snapshot://" not in pure_html + lit_html
    assert str(tmp_path) not in pure_html + lit_html
    hover_json = out / "_static" / "moonbit-semantic" / "hovers.json"
    hover_scripts = list((out / "_static" / "moonbit-semantic").glob("hovers.*.js"))
    assert len(hover_scripts) == 1
    hover_script = hover_scripts[0]
    assert hover_json.is_file()
    assert hover_script.is_file()
    hover_script_text = hover_script.read_text()
    assert "__moonbitSemanticHoverPayloads=" in hover_script_text
    assert "\\u2028" in hover_script_text
    assert "\\u2029" in hover_script_text
    assert "\u2028" not in hover_script_text
    assert "\u2029" not in hover_script_text
    assert pure_html.index(hover_script.name) < pure_html.index("moonbit-semantic.js")
    docs_html = (out / "index.html").read_text()
    assert docs_html.index(hover_script.name) < docs_html.index("moonbit-semantic.js")
    assert list((out / "_static" / "moonbit-semantic" / "assets").rglob("logo.svg"))


def test_local_definition_links_to_deferred_external_source_page(tmp_path: Path) -> None:
    snapshot = _write_snapshot(tmp_path, deferred_external_target=True)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()

    local_page = out / "_moonbit-src" / "local" / "demo" / "src" / "main.mbt.html"
    external_page = out / "_moonbit-src" / "pkg" / "demo" / "1.0" / "guide.mbt.md.html"
    local_html = local_page.read_text()
    external_html = external_page.read_text()

    assert "guide.mbt.md.html#mb-def-" in local_html
    assert 'data-mbt-hover="hover:answer"' in local_html
    assert 'id="mb-def-' in external_html
    assert "data-mbt-hover" not in external_html


def test_strict_literate_page_rejects_unfrozen_include(tmp_path: Path) -> None:
    from sphinx.errors import ExtensionError

    snapshot = _write_snapshot(tmp_path, extra_literate="\n```{include} missing.md\n```\n")
    app, _out, _status, _warning = _project(tmp_path, snapshot, required=True)
    with pytest.raises(ExtensionError, match="not frozen"):
        app.build(force_all=True)


def test_missing_snapshot_gracefully_falls_back(tmp_path: Path) -> None:
    app, out, _status, warning = _project(tmp_path, None, required=False)
    app.build(force_all=True)
    assert app.statuscode == 0
    assert (out / "index.html").is_file()
    assert "semantic source pages are disabled" in warning.getvalue()


def test_required_snapshot_fails_only_supported_builder(tmp_path: Path) -> None:
    from sphinx.errors import ExtensionError

    with pytest.raises(ExtensionError, match="not configured"):
        _project(tmp_path / "html", None, required=True)

    app, out, _status, warning = _project(tmp_path / "text", None, required=True, builder="text")
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()
    assert (out / "index.txt").is_file()


def test_parallel_read_merges_domain_without_worker_domain_instances(tmp_path: Path) -> None:
    snapshot = _write_snapshot(tmp_path)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True, parallel=2)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()
    assert (out / "_moonbit-src" / "index.html").is_file()
