from __future__ import annotations

import ast
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]


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


if __name__ == "__main__":
    unittest.main()
