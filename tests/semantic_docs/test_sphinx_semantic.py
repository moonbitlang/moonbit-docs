from __future__ import annotations

import hashlib
from io import StringIO
import json
from pathlib import Path
import re
import sys
from types import SimpleNamespace

import pytest


ROOT = Path(__file__).resolve().parents[2]
EXT = ROOT / "next" / "_ext"
sys.path.insert(0, str(EXT))

from moonbit_semantic.render import SemanticCodeRenderer
from moonbit_semantic.snapshot import Occurrence, SnapshotError, load_snapshot
from moonbit_semantic.lifecycle import get_outdated


MAIN_SOURCE = (
    "pub fn answer() -> Int { 42 }\n"
    "fn use() -> Int { answer() }\n"
)
LITERATE_SOURCE = """# Included literate guide

Literate Markdown prose survives the normal MyST include.

```moonbit
pub fn lit() -> Int { 7 }
fn use_lit() -> Int { lit() }
```
"""


def _write_snapshot(root: Path) -> Path:
    snapshot = root / "snapshot"
    blobs = snapshot / "blobs" / "sha256"
    occurrences = snapshot / "occurrences" / "ctx"
    hovers = snapshot / "hovers"
    blobs.mkdir(parents=True)
    occurrences.mkdir(parents=True)
    hovers.mkdir(parents=True)

    pure = MAIN_SOURCE
    literate = LITERATE_SOURCE
    pure_digest = hashlib.sha256(pure.encode()).hexdigest()
    literate_digest = hashlib.sha256(literate.encode()).hexdigest()
    (blobs / pure_digest).write_text(pure)
    (blobs / literate_digest).write_text(literate)

    sources = [
        {
            "source_id": "local:main.mbt",
            "path": "main.mbt",
            "blob_digest": f"sha256:{pure_digest}",
            "kind": ".mbt",
            "origin": "local",
            "package": "demo",
            "analysis_status": "required",
            "route_key": "local/demo/src/main.mbt",
        },
        {
            "source_id": "local:literate.mbt.md",
            "path": "literate.mbt.md",
            "blob_digest": f"sha256:{literate_digest}",
            "kind": ".mbt.md",
            "origin": "local",
            "package": "demo/literate",
            "analysis_status": "required",
            "route_key": "local/demo/literate.mbt.md",
        },
    ]
    answer_start = pure.encode().index(b"answer")
    use_start = pure.encode().rindex(b"answer")
    lit_start = literate.encode().index(b"lit()")
    lit_use_start = literate.encode().rindex(b"lit()")
    symbols = [
        {
            "symbol_id": "sym:demo.answer",
            "source_id": "local:main.mbt",
            "selection_range_utf8": [answer_start, answer_start + len(b"answer")],
            "name": "answer",
            "qualified_name": "demo.answer",
            "kind": "function",
            "package": "demo",
            "hover_id": "hover:answer",
        },
        {
            "symbol_id": "sym:demo.lit",
            "source_id": "local:literate.mbt.md",
            "selection_range_utf8": [lit_start, lit_start + len(b"lit")],
            "name": "lit",
            "qualified_name": "demo.lit",
            "kind": "function",
            "package": "demo/literate",
            "hover_id": "hover:answer",
        },
    ]
    (snapshot / "sources.jsonl").write_text("".join(json.dumps(item) + "\n" for item in sources))
    (snapshot / "symbols.jsonl").write_text("".join(json.dumps(item) + "\n" for item in symbols))
    occurrence_records = [
        {
            "source_id": "local:main.mbt",
            "effective_range_utf8": [use_start, use_start + len(b"answer")],
            "candidate_range_utf8": [use_start, use_start + len(b"answer")],
            "symbol_id": "sym:demo.answer",
            "hover_id": "hover:answer",
            "definitions": [
                {
                    "target_source_id": "local:main.mbt",
                    "target_selection_range_utf8": [
                        answer_start,
                        answer_start + len(b"answer"),
                    ],
                    "target_range_utf8": [
                        answer_start,
                        answer_start + len(b"answer"),
                    ],
                    "symbol_id": "sym:demo.answer",
                }
            ],
        },
        {
            "source_id": "local:literate.mbt.md",
            "effective_range_utf8": [lit_use_start, lit_use_start + len(b"lit")],
            "candidate_range_utf8": [lit_use_start, lit_use_start + len(b"lit")],
            "symbol_id": "sym:demo.lit",
            "hover_id": "hover:answer",
            "definitions": [
                {
                    "target_source_id": "local:literate.mbt.md",
                    "target_selection_range_utf8": [
                        lit_start,
                        lit_start + len(b"lit"),
                    ],
                    "target_range_utf8": [
                        lit_start,
                        lit_start + len(b"lit"),
                    ],
                    "symbol_id": "sym:demo.lit",
                }
            ],
        },
    ]
    (occurrences / "main.json").write_text(
        json.dumps({"occurrences": occurrence_records})
    )
    (hovers / "all.json").write_text(
        json.dumps(
            {
                "hover:answer": {
                    "kind": "markdown",
                    "value": """```moonbit
pub fn answer() -> Int { 42 }
```

---

## Details

Returns **the answer** with `Int` type.

- [Safe documentation](https://example.com/docs)
- Nested MoonBit:

  ```mbt check
  fn nested() -> Unit {}
  ```

```c
int answer(void) { return 42; }
```

<script>globalThis.hoverInjected = true</script>
<img src=x onerror=\"globalThis.hoverInjected = true\">
![remote image](https://example.com/tracker.png)
[unsafe](javascript:globalThis.hoverInjected=true)

```{include} hover-secret.txt
```
""",
                },
                "hover:plain": {
                    "kind": "plaintext",
                    "value": "fn plain() -> Int\u2028line separator\u2029**not Markdown** <b>not HTML</b>",
                },
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


def _refresh_snapshot_manifest(snapshot: Path) -> None:
    """Refresh fixture shard digests after a test rewrites its snapshot."""

    manifest_path = snapshot / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    files = []
    for path in sorted(snapshot.rglob("*")):
        if path.is_file() and path != manifest_path:
            data = path.read_bytes()
            files.append(
                {
                    "path": path.relative_to(snapshot).as_posix(),
                    "digest": "sha256:" + hashlib.sha256(data).hexdigest(),
                    "size": len(data),
                }
            )
    manifest["files"] = files
    manifest_path.write_text(json.dumps(manifest))


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
            ]
        )
    )
    (src / "main.mbt").write_text(MAIN_SOURCE)
    (src / "literate.mbt.md").write_text(LITERATE_SOURCE)
    (src / "index.md").write_text(
        "# Test docs\n\nOrdinary docs remain available.\n\n"
        "```moonbit\npub fn answer() -> Int { 42 }\n```\n\n"
        "```{literalinclude} main.mbt\n:language: moonbit\n```\n\n"
        "```{include} literate.mbt.md\n```\n\n"
        "```{toctree}\n:hidden:\n\nsecond\n```\n"
    )
    (src / "second.md").write_text("# Second page\n\nParallel read fixture.\n")
    (src / "hover-secret.txt").write_text("LOCAL_HOVER_SECRET\n")
    (src / "conf.py").write_text(
        (src / "conf.py").read_text()
        + "\nexclude_patterns = ['literate.mbt.md']\n"
    )
    status, warning = StringIO(), StringIO()
    app = Sphinx(src, src, out, doctrees, builder, status=status, warning=warning, freshenv=True, parallel=parallel)
    return app, out, status, warning


def _hover_payloads(out: Path) -> dict[str, dict[str, str]]:
    scripts = list((out / "_static" / "moonbit-semantic").glob("hovers.*.js"))
    assert len(scripts) == 1
    prefix = "globalThis.__moonbitSemanticHoverPayloads="
    source = scripts[0].read_text()
    assert source.startswith(prefix)
    return json.loads(source.removeprefix(prefix).removesuffix(";\n"))


def _highlighted_pre(html: str, language: str) -> str:
    match = re.search(
        rf'<div class="highlight-{re.escape(language)} notranslate"><div class="highlight"><pre>(.*?)</pre>',
        html,
        re.DOTALL,
    )
    assert match is not None
    return match.group(1)


def test_snapshot_loader_and_renderer_use_utf8_byte_ranges(tmp_path: Path) -> None:
    snapshot = load_snapshot(_write_snapshot(tmp_path))
    text = "😀answer\n"
    start = len("😀".encode())
    occurrence = Occurrence("source", (start, start + 6), hover_id="hover:answer")
    html = SemanticCodeRenderer().render(
        text, [occurrence], lambda _item: "target.html"
    )
    assert "😀" in html
    assert 'data-mbt-hover="hover:answer"' in html
    assert 'href="target.html"' in html
    assert "mbt-line-anchor" not in html
    assert "data-mbt-semantic-source" not in html


def test_snapshot_rejects_blob_digest_mismatch(tmp_path: Path) -> None:
    path = _write_snapshot(tmp_path)
    source = json.loads((path / "sources.jsonl").read_text().splitlines()[0])
    blob = path / "blobs" / "sha256" / source["blob_digest"].removeprefix("sha256:")
    blob.write_text("changed")
    with pytest.raises(SnapshotError, match="digest mismatch"):
        load_snapshot(path)


def test_snapshot_rejects_missing_canonical_occurrence_ledger(
    tmp_path: Path,
) -> None:
    path = _write_snapshot(tmp_path)
    sources_path = path / "sources.jsonl"
    sources = [json.loads(line) for line in sources_path.read_text().splitlines()]
    sources[0]["context_id"] = "ctx:missing"
    sources_path.write_text(
        "".join(json.dumps(source) + "\n" for source in sources)
    )
    _refresh_snapshot_manifest(path)

    with pytest.raises(
        SnapshotError,
        match="canonical context has no occurrence ledger",
    ):
        load_snapshot(path)


def test_occurrence_ledger_envelope_supplies_source_and_context(
    tmp_path: Path,
) -> None:
    path = _write_snapshot(tmp_path)
    sources_path = path / "sources.jsonl"
    sources = [json.loads(line) for line in sources_path.read_text().splitlines()]
    sources[0]["context_id"] = "ctx:main"
    sources_path.write_text(
        "".join(json.dumps(source) + "\n" for source in sources)
    )

    ledger_path = path / "occurrences" / "ctx" / "main.json"
    records = json.loads(ledger_path.read_text())["occurrences"]
    occurrence = next(
        record for record in records if record["source_id"] == "local:main.mbt"
    )
    occurrence.pop("source_id")
    occurrence.pop("context_id", None)
    ledger_path.write_text(
        json.dumps(
            {
                "source_id": "local:main.mbt",
                "context_id": "ctx:main",
                "occurrences": [occurrence],
            }
        )
    )
    _refresh_snapshot_manifest(path)

    snapshot = load_snapshot(path)
    inherited = [
        item
        for item in snapshot.occurrences["local:main.mbt"]
        if item.context_id == "ctx:main"
    ]

    assert len(inherited) == 1
    assert inherited[0].source_id == "local:main.mbt"
    assert inherited[0].hover_id == "hover:answer"


def test_occurrence_ledger_rejects_inner_identity_conflict(
    tmp_path: Path,
) -> None:
    path = _write_snapshot(tmp_path)
    ledger_path = path / "occurrences" / "ctx" / "main.json"
    records = json.loads(ledger_path.read_text())["occurrences"]
    conflicting = next(
        record
        for record in records
        if record["source_id"] == "local:literate.mbt.md"
    )
    ledger_path.write_text(
        json.dumps(
            {
                "source_id": "local:main.mbt",
                "context_id": "ctx:main",
                "occurrences": [conflicting],
            }
        )
    )
    _refresh_snapshot_manifest(path)

    with pytest.raises(
        SnapshotError,
        match="source_id conflicts with its ledger envelope",
    ):
        load_snapshot(path)


def test_legacy_snapshot_uses_sorted_context_fallback(tmp_path: Path) -> None:
    path = _write_snapshot(tmp_path)
    occurrence_root = path / "occurrences" / "ctx"
    records = json.loads((occurrence_root / "main.json").read_text())[
        "occurrences"
    ]
    template = next(
        record for record in records if record["source_id"] == "local:main.mbt"
    )
    template.pop("source_id")
    template.pop("context_id", None)
    (occurrence_root / "main.json").unlink()
    for context_id in ("ctx:z", "ctx:a"):
        (occurrence_root / f"{context_id}.json").write_text(
            json.dumps(
                {
                    "source_id": "local:main.mbt",
                    "context_id": context_id,
                    "occurrences": [template],
                }
            )
        )
    _refresh_snapshot_manifest(path)

    snapshot = load_snapshot(path)
    selected_contexts = {
        item.context_id
        for item in snapshot.occurrences["local:main.mbt"]
        if item.context_id is not None
    }

    assert selected_contexts == {"ctx:a"}


def test_snapshot_change_outdates_every_document_page() -> None:
    app = SimpleNamespace(
        _moonbit_semantic_snapshot=SimpleNamespace(corpus_digest="sha256:new"),
        _moonbit_semantic_hover_script="hovers.new.js",
        config=SimpleNamespace(root_doc="index"),
    )
    env = SimpleNamespace(
        moonbit_semantic_corpus_digest="sha256:old",
        found_docs={"second", "index"},
    )

    outdated = get_outdated(app, env, set(), set(), set())

    assert outdated == ["index", "second"]
    assert env.moonbit_semantic_corpus_digest == "sha256:new"


def test_sphinx_renders_document_overlay_and_removes_legacy_source_outputs(
    tmp_path: Path,
) -> None:
    snapshot = _write_snapshot(tmp_path)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True)
    for legacy_name in ("_moonbit-src", "_moonbit-source"):
        legacy = out / legacy_name
        legacy.mkdir(parents=True)
        (legacy / "stale.html").write_text("stale")
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()

    assert not (out / "_moonbit-src").exists()
    assert not (out / "_moonbit-source").exists()
    docs_html = (out / "index.html").read_text()
    assert 'class="mbt-semantic-document-block"' in docs_html
    assert 'data-mbt-hover="hover:answer"' in docs_html
    assert 'id="mb-def-doc-' in docs_html
    assert 'href="#mb-def-doc-' in docs_html
    assert "data-mbt-semantic-source" not in docs_html
    assert "mbt-line-anchor" not in docs_html
    assert "snapshot://" not in docs_html
    assert str(tmp_path) not in docs_html
    hover_json = out / "_static" / "moonbit-semantic" / "hovers.json"
    runtime_script = out / "_static" / "moonbit-semantic" / "moonbit-semantic.js"
    runtime_styles = out / "_static" / "moonbit-semantic" / "moonbit-semantic.css"
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
    assert docs_html.index(hover_script.name) < docs_html.index("moonbit-semantic.js")
    runtime = runtime_script.read_text()
    styles = runtime_styles.read_text()
    assert "activeTarget !== target" in runtime
    assert "belowSpace >= naturalHeight" in runtime
    assert 'raw.kind === "html"' in runtime
    assert 'tooltip.role = "dialog"' in runtime
    assert "pointer-events: auto" in styles
    assert "pointer-events: none" not in styles
    assert not (out / "_static" / "moonbit-semantic" / "assets").exists()


def test_normal_myst_literate_include_preserves_prose_and_semantics(
    tmp_path: Path,
) -> None:
    snapshot = _write_snapshot(tmp_path)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()

    html = (out / "index.html").read_text(encoding="utf-8")
    assert "Included literate guide" in html
    assert "Literate Markdown prose survives the normal MyST include." in html
    assert 'data-mbt-symbol="sym:demo.lit"' in html
    assert 'data-mbt-hover="hover:answer"' in html
    match = re.search(
        r'id="(mb-def-doc-[^"]+)" class="mbt-definition-anchor"></span>'
        r'<a [^>]*data-mbt-symbol="sym:demo\.lit"',
        html,
    )
    assert match is not None
    assert f'href="#{match.group(1)}"' in html
    assert not (out / "literate.mbt.html").exists()
    assert not (out / "_moonbit-src").exists()


def test_hover_markdown_uses_sphinx_highlighting_and_is_sanitized(tmp_path: Path) -> None:
    snapshot = _write_snapshot(tmp_path)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()

    payloads = _hover_payloads(out)
    answer = payloads["hover:answer"]
    assert answer["kind"] == "html"
    fragment = answer["value"]
    assert '<div class="mbt-hover-markdown bd-content' in fragment
    assert "<strong>the answer</strong>" in fragment
    assert "<code" in fragment and "Int" in fragment
    assert "<ul" in fragment
    assert "<hr" in fragment
    assert "mbt-hover-heading" in fragment and "Details" in fragment
    assert "<section" not in fragment
    assert "headerlink" not in fragment
    assert "system-message" not in fragment
    assert 'href="https://example.com/docs"' in fragment
    assert 'class="highlight-moonbit notranslate"' in fragment
    assert 'class="highlight-c notranslate"' in fragment
    assert "highlight-text" in fragment
    assert 'class="kd">fn</span>' in fragment
    assert "data-mbt-hover" not in fragment
    assert "mbt-semantic-token" not in fragment
    assert "mbt-definition" not in fragment
    assert "<script" not in fragment
    assert "<img" not in fragment
    assert 'href="javascript:' not in fragment
    assert "LOCAL_HOVER_SECRET" not in fragment

    docs_html = (out / "index.html").read_text()
    assert _highlighted_pre(fragment, "moonbit") == _highlighted_pre(docs_html, "moonbit")

    plaintext = payloads["hover:plain"]["value"]
    assert "mbt-hover-plaintext" in plaintext
    assert "**not Markdown**" in plaintext
    assert "&lt;b&gt;not HTML&lt;/b&gt;" in plaintext
    assert "<strong>not Markdown</strong>" not in plaintext


def test_missing_snapshot_gracefully_falls_back(tmp_path: Path) -> None:
    app, out, _status, warning = _project(tmp_path, None, required=False)
    app.build(force_all=True)
    assert app.statuscode == 0
    assert (out / "index.html").is_file()
    assert "semantic overlays are disabled" in warning.getvalue()


def test_required_snapshot_fails_only_supported_builder(tmp_path: Path) -> None:
    from sphinx.errors import ExtensionError

    with pytest.raises(ExtensionError, match="not configured"):
        _project(tmp_path / "html", None, required=True)

    app, out, _status, warning = _project(tmp_path / "text", None, required=True, builder="text")
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()
    assert (out / "index.txt").is_file()


def test_parallel_read_keeps_document_overlay_and_destinations(tmp_path: Path) -> None:
    snapshot = _write_snapshot(tmp_path)
    app, out, _status, warning = _project(tmp_path, snapshot, required=True, parallel=2)
    app.build(force_all=True)
    assert app.statuscode == 0, warning.getvalue()
    assert (out / "index.html").is_file()
    assert (out / "second.html").is_file()
    assert not (out / "_moonbit-src").exists()
    html = (out / "index.html").read_text(encoding="utf-8")
    assert 'class="mbt-semantic-document-block"' in html
    assert 'href="#mb-def-doc-' in html
