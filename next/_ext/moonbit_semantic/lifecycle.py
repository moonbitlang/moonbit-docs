"""Sphinx lifecycle for document semantic overlays and Hover assets."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
from typing import Any

from sphinx.errors import ExtensionError
from sphinx.util import logging

from .hover import render_hover_payloads
from .snapshot import SnapshotError, load_snapshot


LOGGER = logging.getLogger(__name__)
SUPPORTED_BUILDERS = {"html", "dirhtml"}


def _snapshot_path(app: Any) -> Path | None:
    configured = app.config.moonbit_semantic_snapshot
    if configured in (None, ""):
        return None
    path = Path(configured).expanduser()
    if not path.is_absolute():
        path = Path(app.confdir) / path
    return path.resolve()


def _hover_payload(hovers: dict[str, Any]) -> str:
    return json.dumps(
        hovers,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def _hover_script_name(hovers: dict[str, Any]) -> str:
    payload = _hover_payload(hovers).encode("utf-8")
    digest = hashlib.sha256(payload).hexdigest()
    return f"hovers.{digest}.js"


def on_builder_inited(app: Any) -> None:
    app._moonbit_semantic_snapshot = None
    app._moonbit_semantic_load_error = None
    app._moonbit_semantic_hovers = None
    app._moonbit_semantic_hover_script = None
    if app.builder.name not in SUPPORTED_BUILDERS:
        return
    path = _snapshot_path(app)
    if path is None:
        message = "moonbit_semantic_snapshot is not configured"
        app._moonbit_semantic_load_error = message
        if app.config.moonbit_semantic_required:
            raise ExtensionError(message)
        LOGGER.warning("%s; semantic overlays are disabled", message)
        return
    try:
        snapshot = load_snapshot(path)
    except SnapshotError as exc:
        app._moonbit_semantic_load_error = str(exc)
        if app.config.moonbit_semantic_required:
            raise ExtensionError(
                f"invalid required MoonBit semantic snapshot: {exc}"
            ) from exc
        LOGGER.warning("MoonBit semantic overlays are disabled: %s", exc)
        return
    app._moonbit_semantic_snapshot = snapshot
    app._moonbit_semantic_hovers = render_hover_payloads(app, snapshot.hovers)
    app._moonbit_semantic_hover_script = _hover_script_name(
        app._moonbit_semantic_hovers
    )
    app.add_css_file("moonbit-semantic/moonbit-semantic.css")
    # A classic script works for local ``file://`` previews in browsers that
    # reject Fetch API requests for sibling JSON files. Keep it before the
    # runtime so deferred scripts expose the payload before listeners run.
    app.add_js_file(
        f"moonbit-semantic/{app._moonbit_semantic_hover_script}",
        defer="defer",
    )
    app.add_js_file("moonbit-semantic/moonbit-semantic.js", defer="defer")


def get_outdated(
    app: Any,
    env: Any,
    added: set[str],
    changed: set[str],
    removed: set[str],
) -> list[str]:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if snapshot is None:
        return []
    old = getattr(env, "moonbit_semantic_corpus_digest", None)
    old_hover_script = getattr(env, "moonbit_semantic_hover_script", None)
    hover_script = app._moonbit_semantic_hover_script
    env.moonbit_semantic_corpus_digest = snapshot.corpus_digest
    env.moonbit_semantic_hover_script = hover_script
    if old != snapshot.corpus_digest or old_hover_script != hover_script:
        found_docs = sorted(getattr(env, "found_docs", ()))
        return found_docs or [app.config.root_doc]

    static = Path(app.outdir) / "_static" / "moonbit-semantic"
    expected = (
        static / "moonbit-semantic.css",
        static / hover_script,
        static / "moonbit-semantic.js",
        static / "hovers.json",
    )
    return [app.config.root_doc] if any(not path.is_file() for path in expected) else []


def _atomic_write_text(path: Path, content: str) -> None:
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    try:
        temporary.write_text(content, encoding="utf-8")
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def _write_static(app: Any, exception: Exception | None) -> None:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if (
        exception is not None
        or snapshot is None
        or app.builder.name not in SUPPORTED_BUILDERS
    ):
        return
    destination = Path(app.outdir) / "_static" / "moonbit-semantic"
    destination.mkdir(parents=True, exist_ok=True)
    package = Path(__file__).parent
    for name in ("moonbit-semantic.css", "moonbit-semantic.js"):
        shutil.copyfile(package / "static" / name, destination / name)
    payload = _hover_payload(app._moonbit_semantic_hovers)
    script_payload = payload.replace("\u2028", "\\u2028").replace(
        "\u2029", "\\u2029"
    )
    _atomic_write_text(destination / "hovers.json", payload)
    _atomic_write_text(
        destination / app._moonbit_semantic_hover_script,
        "globalThis.__moonbitSemanticHoverPayloads=" + script_payload + ";\n",
    )


def _cleanup_stale_outputs(app: Any, exception: Exception | None) -> None:
    if exception is not None or app.builder.name not in SUPPORTED_BUILDERS:
        return
    outdir = Path(app.outdir)
    for legacy in ("_moonbit-src", "_moonbit-source"):
        shutil.rmtree(outdir / legacy, ignore_errors=True)

    static = outdir / "_static" / "moonbit-semantic"
    current = getattr(app, "_moonbit_semantic_hover_script", None)
    if current is None:
        shutil.rmtree(static, ignore_errors=True)
        return
    if static.is_dir():
        for output in static.glob("hovers*.js"):
            if output.name != current:
                output.unlink()
        # These were copied solely for the removed standalone literate/source
        # pages. Document overlays use the normal Sphinx asset pipeline.
        shutil.rmtree(static / "assets", ignore_errors=True)


def on_build_finished(app: Any, exception: Exception | None) -> None:
    _write_static(app, exception)
    _cleanup_stale_outputs(app, exception)
