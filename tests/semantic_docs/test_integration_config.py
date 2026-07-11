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
        self.ids: set[str] = set()
        self.scripts: list[str] = []
        self.has_view_source = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        classes = set((values.get("class") or "").split())
        if values.get("id"):
            self.ids.add(values["id"] or "")
        if values.get("data-mbt-hover"):
            self.hover_ids.append(values["data-mbt-hover"] or "")
        if tag == "a" and "mbt-semantic-token" in classes and values.get("href"):
            self.definition_hrefs.append(values["href"] or "")
        if tag == "script" and values.get("src"):
            self.scripts.append(values["src"] or "")
        self.has_view_source |= "mbt-view-source" in classes


class SemanticDocumentationConfigurationTests(unittest.TestCase):
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
        self.assertIn("moonbit_semantic_source_prefix", assignments)

        source = (REPO_ROOT / "next" / "conf.py").read_text()
        self.assertIn("'moonbit_semantic'", source)
        self.assertIn("'_moonbit-src'", source)

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
                            "moonbit_semantic_source_prefix = '_moonbit-src'",
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

    def test_snapshot_and_html_outputs_exist(self) -> None:
        self.assertTrue(self.snapshot.is_dir(), self.snapshot)
        self.assertTrue((self.snapshot / "manifest.json").is_file())
        self.assertTrue((self.html / "index.html").is_file())

    def test_generated_html_does_not_leak_local_file_urls(self) -> None:
        source_root = self.html / "_moonbit-src"
        self.assertTrue(source_root.is_dir(), source_root)
        source_pages = list(source_root.rglob("*.html"))
        self.assertTrue(source_pages, source_root)

        has_semantic_source = False
        has_line_anchor = False
        has_hover = False
        has_definition = False
        for page in source_pages:
            rendered = page.read_text(errors="replace")
            self.assertNotIn("file://", rendered, page)
            self.assertNotIn(str(REPO_ROOT), rendered, page)
            has_semantic_source |= "data-mbt-semantic-source" in rendered
            has_line_anchor |= 'id="L' in rendered
            has_hover |= "data-mbt-hover" in rendered
            has_definition |= 'id="mb-def-' in rendered

        self.assertTrue(has_semantic_source, "no semantic source page was rendered")
        self.assertTrue(has_line_anchor, "no source line anchor was rendered")
        self.assertTrue(has_hover, "no hover-enabled token was rendered")
        self.assertTrue(has_definition, "no definition anchor was rendered")

    def test_hover_payloads_and_definition_links_are_closed(self) -> None:
        static = self.html / "_static" / "moonbit-semantic"
        hover_scripts = list(static.glob("hovers.*.js"))
        self.assertEqual(len(hover_scripts), 1, hover_scripts)
        hover_script = hover_scripts[0]
        payload_source = hover_script.read_text(encoding="utf-8")
        prefix = "globalThis.__moonbitSemanticHoverPayloads="
        self.assertTrue(payload_source.startswith(prefix), hover_script)
        payloads = json.loads(payload_source.removeprefix(prefix).removesuffix(";\n"))

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
                self.assertFalse(target.scheme, f"{page}: {href}")
                target_page = page if not target.path else page.parent / unquote(target.path)
                target_page = target_page.resolve()
                self.assertTrue(target_page.is_relative_to(self.html), f"{page}: {href}")
                self.assertTrue(target_page.is_file(), f"{page}: {href}")
                if target.fragment:
                    self.assertIn(unquote(target.fragment), parse(target_page).ids, f"{page}: {href}")

        self.assertGreater(hover_occurrences, 0)
        self.assertGreater(definition_links, 0)


if __name__ == "__main__":
    unittest.main()
