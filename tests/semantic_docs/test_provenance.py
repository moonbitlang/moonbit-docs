from __future__ import annotations

import codecs
import hashlib
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest


ROOT = Path(__file__).resolve().parents[2]
EXT = ROOT / "next" / "_ext"
sys.path.insert(0, str(EXT))

from sphinx.directives.code import LiteralIncludeReader

from moonbit_semantic.provenance import (
    build_literalinclude_provenance,
    map_source_range,
    provenance_is_current,
)
from moonbit_semantic.nodes import merge_semantic_blocks, purge_semantic_blocks
from moonbit_semantic.snapshot import SemanticSnapshot, Source


class LiteralIncludeProvenanceTests(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self._temporary.cleanup)

    def path(self, name: str) -> Path:
        return Path(self._temporary.name) / name

    def _golden(self, source: str, options: dict[str, object], path: Path):
        path.write_text(source, encoding="utf-8")
        upstream_options = dict(options)
        displayed, _lines = LiteralIncludeReader(
            str(path), upstream_options, SimpleNamespace(source_encoding="utf-8")
        ).read()
        provenance = build_literalinclude_provenance(
            path.read_bytes(),
            displayed,
            options,
            source_id="local:sample.mbt",
            target="sample.mbt",
        )
        self.assertTrue(provenance["valid"], provenance.get("reason"))
        self.assertEqual(provenance["display_digest"], "sha256:" + hashlib.sha256(displayed.encode()).hexdigest())
        return displayed, provenance

    def test_start_end_dedent_prepend_append_map_exact_identifier(self) -> None:
        source = (
            "header\n"
            "// begin\n"
            "    pub fn answer() -> Int {\n"
            "      answer()\n"
            "    }\n"
            "// end\n"
            "footer\n"
        )
        path = self.path("sample.mbt")
        options = {
            "start-after": "// begin",
            "end-before": "// end",
            "dedent": 4,
            "prepend": "fn wrapper {",
            "append": "}",
        }
        displayed, provenance = self._golden(source, options, path)
        self.assertEqual(
            displayed,
            "fn wrapper {\npub fn answer() -> Int {\n  answer()\n}\n}\n",
        )
        source_start = source.encode().index(b"answer")
        mapped = map_source_range(provenance, (source_start, source_start + len(b"answer")))
        self.assertIsNotNone(mapped)
        assert mapped is not None
        self.assertEqual(displayed.encode()[mapped[0] : mapped[1]], b"answer")
        self.assertTrue(any(segment["source"] is None for segment in provenance["segments"]))

    def test_lines_and_automatic_dedent_match_upstream(self) -> None:
        source = "    first\n      second\n    third\n"
        path = self.path("sample.mbt")
        displayed, provenance = self._golden(source, {"lines": "1,3", "dedent": None}, path)
        self.assertEqual(displayed, "first\nthird\n")
        third = source.encode().index(b"third")
        mapped = map_source_range(provenance, (third, third + 5))
        self.assertEqual(displayed.encode()[mapped[0] : mapped[1]], b"third")

    def test_start_at_end_at_and_tab_expansion_match_upstream(self) -> None:
        source = "skip\n\tpub fn tabbed() -> Int { 0 }\nstop\ntrailer\n"
        path = self.path("sample.mbt")
        displayed, provenance = self._golden(
            source,
            {"start-at": "pub fn", "end-at": "stop", "tab-width": 4},
            path,
        )
        self.assertEqual(displayed, "    pub fn tabbed() -> Int { 0 }\nstop\n")
        start = source.encode().index(b"tabbed")
        mapped = map_source_range(provenance, (start, start + len(b"tabbed")))
        self.assertEqual(displayed.encode()[mapped[0] : mapped[1]], b"tabbed")

    def test_synthetic_and_tab_bytes_are_not_guessed(self) -> None:
        raw = b"\tanswer\n"
        displayed = "  answer\n"
        provenance = build_literalinclude_provenance(
            raw,
            displayed,
            {"tab-width": 2},
            source_id="local:sample.mbt",
            target="sample.mbt",
        )
        self.assertIsNone(map_source_range(provenance, (0, 1)))
        self.assertEqual(map_source_range(provenance, (1, 7)), (2, 8))

    def test_utf8_bom_and_crlf_offsets_still_use_raw_blob_bytes(self) -> None:
        raw = codecs.BOM_UTF8 + b"  pub fn answer() -> Int { 1 }\r\n"
        displayed = "pub fn answer() -> Int { 1 }\n"
        provenance = build_literalinclude_provenance(
            raw,
            displayed,
            {"encoding": "utf-8-sig", "dedent": 2},
            source_id="local:sample.mbt",
            target="sample.mbt",
        )
        self.assertTrue(provenance["valid"], provenance.get("reason"))
        start = raw.index(b"answer")
        mapped = map_source_range(provenance, (start, start + 6))
        self.assertEqual(displayed.encode()[mapped[0] : mapped[1]], b"answer")

    def test_display_or_source_digest_mismatch_fails_closed(self) -> None:
        raw = b"pub fn answer() -> Int { 42 }\n"
        digest = hashlib.sha256(raw).hexdigest()
        source = Source("local:sample.mbt", "sample.mbt", f"sha256:{digest}", ".mbt")
        snapshot = SemanticSnapshot(
            root=Path("."),
            manifest={},
            sources={source.source_id: source},
            assets={},
            symbols={},
            occurrences={},
            hovers={},
            corpus_digest="test",
        )
        # Keep this unit test independent of the on-disk blob loader.
        snapshot.blob_bytes = lambda _source: raw  # type: ignore[method-assign]
        provenance = build_literalinclude_provenance(
            raw,
            raw.decode(),
            {},
            source_id=source.source_id,
            target="sample.mbt",
        )
        self.assertTrue(provenance_is_current(provenance, raw.decode(), snapshot))
        self.assertFalse(provenance_is_current(provenance, "changed", snapshot))
        provenance["source_digest"] = "sha256:" + "0" * 64
        self.assertFalse(provenance_is_current(provenance, raw.decode(), snapshot))

    def test_parallel_environment_state_merges_and_purges_by_docname(self) -> None:
        key = ("local:sample.mbt", "sym:answer", 4, 10)
        env = SimpleNamespace(
            moonbit_semantic_document_definitions={
                "old": {key: [(0, "old-anchor")]}
            }
        )
        other = SimpleNamespace(
            moonbit_semantic_document_definitions={
                "new": {key: [(1, "new-anchor")]},
                "ignored": {key: [(2, "ignored-anchor")]},
            }
        )
        merge_semantic_blocks(None, env, ["new"], other)
        self.assertEqual(
            env.moonbit_semantic_document_definitions,
            {
                "old": {key: [(0, "old-anchor")]},
                "new": {key: [(1, "new-anchor")]},
            },
        )
        purge_semantic_blocks(None, env, "old")
        self.assertEqual(
            env.moonbit_semantic_document_definitions,
            {"new": {key: [(1, "new-anchor")]}},
        )


if __name__ == "__main__":
    unittest.main()
