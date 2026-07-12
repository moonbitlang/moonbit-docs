from __future__ import annotations

import hashlib
from html.parser import HTMLParser
from io import StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
EXT = ROOT / "next" / "_ext"
sys.path.insert(0, str(EXT))


class _PreText(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.depth = 0
        self.values: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "pre":
            self.depth += 1

    def handle_endtag(self, tag: str) -> None:
        if tag == "pre" and self.depth:
            self.depth -= 1

    def handle_data(self, data: str) -> None:
        if self.depth:
            self.values.append(data)


class SemanticBlockSphinxTests(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self._temporary.cleanup)
        self.root = Path(self._temporary.name)

    def _snapshot(self, source: bytes) -> Path:
        snapshot = self.root / "snapshot"
        blobs = snapshot / "blobs" / "sha256"
        blobs.mkdir(parents=True)
        digest = hashlib.sha256(source).hexdigest()
        (blobs / digest).write_bytes(source)
        answer = source.index(b"answer")
        use = source.rindex(b"answer")
        source_id = "local:code.mbt"
        records = [
            {
                "source_id": source_id,
                "path": "code.mbt",
                "blob_digest": f"sha256:{digest}",
                "kind": ".mbt",
                "origin": "local",
                "package": "demo",
                "analysis_status": "required",
                "route_key": "local/demo/code.mbt",
            }
        ]
        symbols = [
            {
                "symbol_id": "sym:answer",
                "source_id": source_id,
                "selection_range_utf8": [answer, answer + 6],
                "name": "answer",
                "kind": "function",
                "package": "demo",
                "hover_id": "hover:answer",
            }
        ]
        occurrences = [
            {
                "source_id": source_id,
                "effective_range_utf8": [use, use + 6],
                "symbol_id": "sym:answer",
                "hover_id": "hover:answer",
                "definitions": [
                    {
                        "target_source_id": source_id,
                        "target_selection_range_utf8": [answer, answer + 6],
                        "symbol_id": "sym:answer",
                    }
                ],
            }
        ]
        (snapshot / "sources.jsonl").write_text(
            "".join(json.dumps(record) + "\n" for record in records), encoding="utf-8"
        )
        (snapshot / "symbols.jsonl").write_text(
            "".join(json.dumps(record) + "\n" for record in symbols), encoding="utf-8"
        )
        (snapshot / "occurrences.jsonl").write_text(
            "".join(json.dumps(record) + "\n" for record in occurrences), encoding="utf-8"
        )
        files = []
        for path in sorted(snapshot.rglob("*")):
            if path.is_file():
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
                    "corpus_digest": "test",
                    "files": files,
                }
            ),
            encoding="utf-8",
        )
        return snapshot

    def _project(
        self,
        source: bytes,
        *,
        stale: bool = False,
        builder: str = "html",
        extra_options: str = "",
    ):
        from sphinx.application import Sphinx

        snapshot = self._snapshot(source)
        docs = self.root / f"docs-{builder}-{stale}"
        out = self.root / f"out-{builder}-{stale}"
        doctrees = self.root / f"doctrees-{builder}-{stale}"
        docs.mkdir()
        (docs / "conf.py").write_text(
            "\n".join(
                [
                    "import sys",
                    f"sys.path.insert(0, {str(EXT)!r})",
                    f"sys.path.insert(0, {str(docs)!r})",
                    "extensions = ['myst_parser', 'moonbit_semantic']",
                    "source_suffix = {'.md': 'markdown'}",
                    "master_doc = 'index'",
                    "project = 'block-test'",
                    "html_theme = 'basic'",
                    f"moonbit_semantic_snapshot = {str(snapshot)!r}",
                    "moonbit_semantic_required = True",
                ]
            ),
            encoding="utf-8",
        )
        actual = source.replace(b"answer()", b"changed()", 1) if stale else source
        (docs / "code.mbt").write_bytes(actual)
        (docs / "index.md").write_text(
            f"""# Included code

```{{literalinclude}} code.mbt
:language: moonbit
:start-after: // begin
:end-before: // end
:dedent: 4
:prepend: // synthetic display line
{extra_options}
```
""",
            encoding="utf-8",
        )
        status, warning = StringIO(), StringIO()
        app = Sphinx(
            docs,
            docs,
            out,
            doctrees,
            builder,
            status=status,
            warning=warning,
            freshenv=True,
            parallel=1,
        )
        return app, out, status, warning

    def test_html_overlay_has_hover_definition_and_exact_copy_text(self) -> None:
        source = (
            b"// begin\n"
            b"    pub fn answer() -> Int { 42 }\n"
            b"    fn use() -> Int { answer() }\n"
            b"// end\n"
        )
        app, out, _status, warning = self._project(source)
        app.build(force_all=True)
        self.assertEqual(app.statuscode, 0, warning.getvalue())
        html = (out / "index.html").read_text(encoding="utf-8")
        self.assertIn('class="mbt-semantic-document-block"', html)
        self.assertIn('data-mbt-hover="hover:answer"', html)
        self.assertIn("#mb-def-", html)
        self.assertNotIn("View source", html)
        self.assertNotIn("mbt-view-source", html)
        self.assertIn('<div class="highlight-moonbit notranslate">', html)
        self.assertFalse((out / "_moonbit-src").exists())
        self.assertNotIn("data-mbt-semantic-source", html)
        self.assertNotIn("mbt-line-anchor", html)
        parser = _PreText()
        parser.feed(html)
        self.assertEqual(
            "".join(parser.values),
            "// synthetic display line\npub fn answer() -> Int { 42 }\nfn use() -> Int { answer() }\n",
        )

    def test_stale_include_keeps_original_sphinx_literal_block(self) -> None:
        source = b"// begin\n    pub fn answer() -> Int { 42 }\n// end\n"
        app, out, _status, warning = self._project(source, stale=True)
        app.build(force_all=True)
        self.assertEqual(app.statuscode, 0, warning.getvalue())
        html = (out / "index.html").read_text(encoding="utf-8")
        self.assertNotIn("mbt-semantic-document-block", html)
        self.assertIn("changed", html)

    def test_non_html_builder_keeps_literal_block(self) -> None:
        source = b"// begin\n    pub fn answer() -> Int { 42 }\n// end\n"
        app, out, _status, warning = self._project(source, builder="text")
        app.build(force_all=True)
        self.assertEqual(app.statuscode, 0, warning.getvalue())
        rendered = (out / "index.txt").read_text(encoding="utf-8")
        self.assertIn("pub fn answer", rendered)
        self.assertNotIn("View source", rendered)

    def test_existing_presentation_options_keep_sphinx_renderer(self) -> None:
        source = (
            b"// begin\n"
            b"    pub fn answer() -> Int { 42 }\n"
            b"    fn use() -> Int { answer() }\n"
            b"// end\n"
        )
        app, out, _status, warning = self._project(
            source,
            extra_options=":emphasize-lines: 2",
        )
        app.build(force_all=True)
        self.assertEqual(app.statuscode, 0, warning.getvalue())
        html = (out / "index.html").read_text(encoding="utf-8")
        self.assertNotIn("mbt-semantic-document-block", html)
        self.assertIn('class="hll"', html)


if __name__ == "__main__":
    unittest.main()
