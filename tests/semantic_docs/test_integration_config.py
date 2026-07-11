from __future__ import annotations

import ast
from html.parser import HTMLParser
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from urllib.parse import unquote, urlsplit


REPO_ROOT = Path(__file__).resolve().parents[2]


class _SemanticOutputParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.hover_ids: list[str] = []
        self.definition_hrefs: list[str] = []
        self.semantic_links: list[tuple[str, str | None]] = []
        self.source_download_hrefs: list[str] = []
        self.ids: set[str] = set()
        self.scripts: list[str] = []
        self.has_view_source = False
        self.has_semantic_document = False
        self.has_semantic_source = False
        self.has_line_anchor = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        classes = set((values.get("class") or "").split())
        if values.get("id"):
            self.ids.add(values["id"] or "")
        if values.get("data-mbt-hover"):
            self.hover_ids.append(values["data-mbt-hover"] or "")
        if tag == "a" and "mbt-semantic-token" in classes and values.get("href"):
            self.definition_hrefs.append(values["href"] or "")
            self.semantic_links.append(
                (values["href"] or "", values.get("data-mbt-hover"))
            )
        if tag == "a" and "_sources/" in (values.get("href") or ""):
            self.source_download_hrefs.append(values["href"] or "")
        if tag == "script" and values.get("src"):
            self.scripts.append(values["src"] or "")
        self.has_view_source |= "mbt-view-source" in classes
        self.has_semantic_document |= "mbt-semantic-document-block" in classes
        self.has_semantic_source |= "mbt-semantic-source" in classes
        self.has_line_anchor |= "mbt-line-anchor" in classes


class SemanticDocumentationConfigurationTests(unittest.TestCase):
    def test_indent_workaround_declares_parallel_safety(self) -> None:
        path = REPO_ROOT / "next" / "_ext" / "indent.py"
        spec = importlib.util.spec_from_file_location("moonbit_docs_indent_test", path)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader if spec else None)
        module = importlib.util.module_from_spec(spec)
        assert spec is not None and spec.loader is not None
        spec.loader.exec_module(module)

        metadata = module.setup(None)

        self.assertTrue(metadata["parallel_read_safe"])
        self.assertTrue(metadata["parallel_write_safe"])

    def test_sphinx_configuration_registers_the_public_contract(self) -> None:
        tree = ast.parse((REPO_ROOT / "next" / "conf.py").read_text())
        assignments = {
            target.id
            for node in ast.walk(tree)
            if isinstance(node, (ast.Assign, ast.AnnAssign))
            for target in (
                node.targets if isinstance(node, ast.Assign) else [node.target]
            )
            if isinstance(target, ast.Name)
        }

        self.assertIn("moonbit_semantic_snapshot", assignments)
        self.assertIn("moonbit_semantic_required", assignments)
        self.assertNotIn("moonbit_semantic_source_prefix", assignments)

        source = (REPO_ROOT / "next" / "conf.py").read_text()
        self.assertIn("'moonbit_semantic'", source)
        self.assertNotIn("'_moonbit-src'", source)
        self.assertIn("html_copy_source = False", source)
        self.assertIn("html_show_sourcelink = False", source)
        self.assertIn('"use_source_button": False', source)
        self.assertIn('"use_download_button": False', source)

    @unittest.skipUnless(shutil.which("just"), "just is not installed")
    def test_semantic_recipes_preserve_the_build_order(self) -> None:
        result = subprocess.run(
            ["just", "--dry-run", "docs-html-semantic"],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        commands = result.stdout + result.stderr
        index = commands.index("build --repo-root . --output")
        validate = commands.index("validate --snapshot")
        sphinx = commands.index("MOONBIT_SEMANTIC_REQUIRED=1")
        self.assertLess(index, validate)
        self.assertLess(validate, sphinx)

    @unittest.skipUnless(
        importlib.util.find_spec("sphinx"), "Sphinx is not installed"
    )
    def test_missing_snapshot_is_optional_unless_strict_mode_is_enabled(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            (source / "index.md").write_text("# Semantic docs integration test\n")
            extension_path = REPO_ROOT / "next" / "_ext"
            missing_snapshot = root / "does-not-exist"

            def build(required: bool, output_name: str) -> subprocess.CompletedProcess[str]:
                (source / "conf.py").write_text(
                    "\n".join(
                        [
                            "import sys",
                            f"sys.path.insert(0, {str(extension_path)!r})",
                            "extensions = ['myst_parser', 'moonbit_semantic']",
                            "source_suffix = {'.md': 'markdown'}",
                            f"moonbit_semantic_snapshot = {str(missing_snapshot)!r}",
                            f"moonbit_semantic_required = {required!r}",
                        ]
                    )
                    + "\n"
                )
                return subprocess.run(
                    [
                        sys.executable,
                        "-m",
                        "sphinx",
                        "-q",
                        "-b",
                        "html",
                        str(source),
                        str(root / output_name),
                    ],
                    check=False,
                    capture_output=True,
                    text=True,
                )

            optional = build(required=False, output_name="optional-html")
            self.assertEqual(optional.returncode, 0, optional.stderr)

            strict = build(required=True, output_name="strict-html")
            self.assertNotEqual(strict.returncode, 0, strict.stdout + strict.stderr)
            self.assertIn("snapshot", (strict.stdout + strict.stderr).lower())


@unittest.skipUnless(
    os.getenv("MOONBIT_SEMANTIC_E2E") == "1",
    "set MOONBIT_SEMANTIC_E2E=1 after a strict semantic HTML build",
)
class SemanticDocumentationEndToEndTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        snapshot = os.getenv("MOONBIT_SEMANTIC_SNAPSHOT", "semantic-snapshot")
        html = os.getenv("MOONBIT_SEMANTIC_HTML", "next/_build/html")
        cls.snapshot = (REPO_ROOT / snapshot).resolve()
        cls.html = (REPO_ROOT / html).resolve()
        target_table = cls.snapshot / "external-targets.jsonl"
        cls.external_definition_urls = {
            record["url"]
            for line in target_table.read_text(encoding="utf-8").splitlines()
            if line.strip()
            and (record := json.loads(line)).get("status") == "exact"
        } if target_table.is_file() else set()

    def test_snapshot_and_html_outputs_exist(self) -> None:
        self.assertTrue(self.snapshot.is_dir(), self.snapshot)
        self.assertTrue((self.snapshot / "manifest.json").is_file())
        self.assertTrue((self.html / "index.html").is_file())

    def test_generated_html_contains_only_document_semantic_overlays(self) -> None:
        self.assertFalse((self.html / "_moonbit-src").exists())
        self.assertFalse((self.html / "_moonbit-source").exists())
        self.assertFalse((self.html / "_sources").exists())
        pages = list(self.html.rglob("*.html"))
        self.assertTrue(pages, self.html)

        has_semantic_document = False
        has_hover = False
        has_definition = False
        for page in pages:
            rendered = page.read_text(errors="replace")
            self.assertNotIn("file://", rendered, page)
            self.assertNotIn(str(REPO_ROOT), rendered, page)
            parser = _SemanticOutputParser()
            parser.feed(rendered)
            self.assertFalse(parser.source_download_hrefs, page)
            self.assertFalse(parser.has_semantic_source, page)
            self.assertFalse(parser.has_line_anchor, page)
            has_semantic_document |= parser.has_semantic_document
            has_hover |= "data-mbt-hover" in rendered
            has_definition |= 'id="mb-def-doc-' in rendered

        self.assertTrue(has_semantic_document, "no semantic document block was rendered")
        self.assertTrue(has_hover, "no hover-enabled token was rendered")
        self.assertTrue(has_definition, "no document definition anchor was rendered")

    def test_hover_payloads_and_definition_links_are_closed(self) -> None:
        static = self.html / "_static" / "moonbit-semantic"
        hover_scripts = list(static.glob("hovers.*.js"))
        self.assertEqual(len(hover_scripts), 1, hover_scripts)
        hover_script = hover_scripts[0]
        payload_source = hover_script.read_text(encoding="utf-8")
        prefix = "globalThis.__moonbitSemanticHoverPayloads="
        self.assertTrue(payload_source.startswith(prefix), hover_script)
        payloads = json.loads(payload_source.removeprefix(prefix).removesuffix(";\n"))
        rich_hovers = 0
        for hover_id, payload in payloads.items():
            self.assertEqual(payload.get("kind"), "html", hover_id)
            fragment = payload.get("value")
            self.assertIsInstance(fragment, str, hover_id)
            lowered = fragment.lower()
            self.assertNotIn("<script", lowered, hover_id)
            self.assertNotIn('href="javascript:', lowered, hover_id)
            self.assertNotIn("file://", lowered, hover_id)
            self.assertNotIn(str(REPO_ROOT), fragment, hover_id)
            rich_hovers += "highlight-moonbit" in fragment
        self.assertGreater(rich_hovers, 0)

        pages = list(self.html.rglob("*.html"))
        self.assertTrue(pages, self.html)
        parsed_pages: dict[Path, _SemanticOutputParser] = {}

        def parse(page: Path) -> _SemanticOutputParser:
            resolved = page.resolve()
            if resolved not in parsed_pages:
                parser = _SemanticOutputParser()
                parser.feed(resolved.read_text(encoding="utf-8", errors="replace"))
                parsed_pages[resolved] = parser
            return parsed_pages[resolved]

        hover_occurrences = 0
        definition_links = 0
        for page in pages:
            parser = parse(page)
            self.assertFalse(parser.has_view_source, page)
            for hover_id in parser.hover_ids:
                hover_occurrences += 1
                self.assertIn(hover_id, payloads, f"{page}: {hover_id}")
            if parser.hover_ids:
                preload = next(
                    (index for index, src in enumerate(parser.scripts) if hover_script.name in src),
                    None,
                )
                runtime = next(
                    (index for index, src in enumerate(parser.scripts) if src.endswith("moonbit-semantic.js")),
                    None,
                )
                self.assertIsNotNone(preload, page)
                self.assertIsNotNone(runtime, page)
                self.assertLess(preload, runtime, page)

            for href in parser.definition_hrefs:
                definition_links += 1
                target = urlsplit(href)
                if target.scheme or target.netloc:
                    self.assertEqual(target.scheme, "https", f"{page}: {href}")
                    self.assertEqual(target.netloc, "mooncakes.io", f"{page}: {href}")
                    self.assertTrue(target.path.startswith("/docs/"), f"{page}: {href}")
                    self.assertFalse(target.query, f"{page}: {href}")
                    self.assertTrue(target.fragment, f"{page}: {href}")
                    self.assertNotIn("%3a", target.fragment.lower(), f"{page}: {href}")
                    self.assertIn(href, self.external_definition_urls, f"{page}: {href}")
                    continue
                target_page = page if not target.path else page.parent / unquote(target.path)
                target_page = target_page.resolve()
                self.assertTrue(target_page.is_relative_to(self.html), f"{page}: {href}")
                self.assertTrue(target_page.is_file(), f"{page}: {href}")
                if target.fragment:
                    self.assertIn(unquote(target.fragment), parse(target_page).ids, f"{page}: {href}")

        self.assertGreater(hover_occurrences, 0)
        self.assertGreater(definition_links, 0)

    def test_fullstack_mixed_targets_render_core_json_semantics(self) -> None:
        page = self.html / "tutorial" / "fullstack-one-project.html"
        rendered = page.read_text(encoding="utf-8")
        frontend_start = rendered.index(
            '<section id="step-3-implement-the-frontend-js">'
        )
        backend_start = rendered.index(
            '<section id="step-4-implement-the-backend-native">'
        )
        backend_end = rendered.index('<section id="step-5-', backend_start)
        frontend = _SemanticOutputParser()
        frontend.feed(rendered[frontend_start:backend_start])
        backend = _SemanticOutputParser()
        backend.feed(rendered[backend_start:backend_end])

        expected = {
            "https://mooncakes.io/docs/moonbitlang/core/json#from_json",
            "https://mooncakes.io/docs/moonbitlang/core/json#parse",
            "https://mooncakes.io/docs/moonbitlang/core/json#Json::stringify",
        }
        for section in (frontend, backend):
            links = {
                href
                for href, hover_id in section.semantic_links
                if hover_id
            }
            self.assertTrue(expected <= links, page)

        self.assertIn(
            "https://mooncakes.io/docs/moonbitlang/core/prelude#ToJson",
            rendered,
        )


if __name__ == "__main__":
    unittest.main()
