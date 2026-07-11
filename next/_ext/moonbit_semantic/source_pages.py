"""Sphinx lifecycle and Hackage-style additional source pages."""

from __future__ import annotations

import hashlib
from html import escape
import json
import os
from pathlib import Path
import shutil
from typing import Any, Iterator

from sphinx.errors import ExtensionError
from sphinx.util import logging
from sphinx.util.osutil import relative_uri

from .literate import render_literate
from .render import SemanticCodeRenderer
from .routing import source_pagename, symbol_anchor, target_fingerprint
from .snapshot import DefinitionTarget, Occurrence, SemanticSnapshot, SnapshotError, load_snapshot


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


def _hover_payload(snapshot: SemanticSnapshot) -> str:
    return json.dumps(snapshot.hovers, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _hover_script_name(snapshot: SemanticSnapshot) -> str:
    payload = _hover_payload(snapshot).encode("utf-8")
    digest = hashlib.sha256(payload).hexdigest()
    return f"hovers.{digest}.js"


def on_builder_inited(app: Any) -> None:
    app._moonbit_semantic_snapshot = None
    app._moonbit_semantic_load_error = None
    app._moonbit_semantic_hover_script = None
    if app.builder.name not in SUPPORTED_BUILDERS:
        return
    path = _snapshot_path(app)
    if path is None:
        message = "moonbit_semantic_snapshot is not configured"
        app._moonbit_semantic_load_error = message
        if app.config.moonbit_semantic_required:
            raise ExtensionError(message)
        LOGGER.warning("%s; semantic source pages are disabled", message)
        return
    try:
        snapshot = load_snapshot(path)
    except SnapshotError as exc:
        app._moonbit_semantic_load_error = str(exc)
        if app.config.moonbit_semantic_required:
            raise ExtensionError(f"invalid required MoonBit semantic snapshot: {exc}") from exc
        LOGGER.warning("MoonBit semantic snapshot disabled: %s", exc)
        return
    app._moonbit_semantic_snapshot = snapshot
    app._moonbit_semantic_hover_script = _hover_script_name(snapshot)
    domain = app.env.get_domain("mbtsem")
    domain.register_snapshot(snapshot, app.config.moonbit_semantic_source_prefix)
    app.add_css_file("moonbit-semantic/moonbit-semantic.css")
    # A classic script works for local ``file://`` previews in browsers that
    # reject Fetch API requests for sibling JSON files. Keep it before the
    # runtime so deferred scripts expose the payload before hover listeners run.
    app.add_js_file(
        f"moonbit-semantic/{app._moonbit_semantic_hover_script}",
        defer="defer",
    )
    app.add_js_file("moonbit-semantic/moonbit-semantic.js", defer="defer")


def _source_line(snapshot: SemanticSnapshot, target: DefinitionTarget) -> int:
    source = snapshot.sources[target.source_id]
    data = snapshot.blob_bytes(source)
    return data.count(b"\n", 0, target.selection_range[0]) + 1


def _target_href(app: Any, frompage: str, occurrence: Occurrence) -> str | None:
    snapshot = app._moonbit_semantic_snapshot
    targets = occurrence.definitions
    if not targets:
        if occurrence.role == "definition" and occurrence.symbol_id:
            return "#" + symbol_anchor(occurrence.symbol_id)
        return None
    if len(targets) > 1:
        page = f"{app.config.moonbit_semantic_source_prefix.strip('/')}/_targets/{target_fingerprint(targets)}"
        return app.builder.get_relative_uri(frompage, page)
    target = targets[0]
    source = snapshot.sources[target.source_id]
    page = source_pagename(app.config.moonbit_semantic_source_prefix, source)
    uri = app.builder.get_relative_uri(frompage, page)
    if target.symbol_id and target.symbol_id in snapshot.symbols:
        return uri + "#" + symbol_anchor(target.symbol_id)
    # A provider can return a location without a stable symbol identity.
    return uri + f"#L{_source_line(snapshot, target)}"


def _standalone_page(app: Any, pagename: str, title: str, body: str, source: Any = None) -> str:
    current = app.builder.get_target_uri(pagename)
    css = relative_uri(current, "_static/moonbit-semantic/moonbit-semantic.css")
    pygments = relative_uri(current, "_static/pygments.css")
    hover_script = app._moonbit_semantic_hover_script
    hovers = relative_uri(current, f"_static/moonbit-semantic/{hover_script}")
    js = relative_uri(current, "_static/moonbit-semantic/moonbit-semantic.js")
    header = ""
    if source is not None:
        identity = ""
        if source.module:
            identity = source.module + ("@" + source.version if source.version else "")
        header = (
            '<header class="mbt-source-header"><span class="mbt-source-path">'
            + escape(source.path)
            + "</span>"
            + (f"<span>{escape(identity)}</span>" if identity else "")
            + "</header>"
        )
    return (
        "<!doctype html><html><head><meta charset=\"utf-8\">"
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<meta name="robots" content="index,follow">'
        f"<title>{escape(title)} — MoonBit source</title>"
        f'<link rel="stylesheet" href="{escape(pygments, quote=True)}">'
        f'<link rel="stylesheet" href="{escape(css, quote=True)}">'
        f'<script defer src="{escape(hovers, quote=True)}"></script>'
        f'<script defer src="{escape(js, quote=True)}"></script>'
        f'</head><body><main class="mbt-source-page">{header}{body}</main></body></html>'
    )


def _write_page(app: Any, pagename: str, title: str, body: str, source: Any = None) -> None:
    output = Path(app.builder.get_outfilename(pagename))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(_standalone_page(app, pagename, title, body, source), encoding="utf-8")


def _render_pure_source(app: Any, source: Any, pagename: str) -> str:
    snapshot = app._moonbit_semantic_snapshot
    renderer = SemanticCodeRenderer()
    return renderer.render(
        snapshot.source_text(source),
        snapshot.occurrences.get(source.source_id, ()),
        lambda occurrence: _target_href(app, pagename, occurrence),
        source_page=True,
    )


def _target_sets(snapshot: SemanticSnapshot) -> dict[str, tuple[DefinitionTarget, ...]]:
    result = {}
    for occurrences in snapshot.occurrences.values():
        for occurrence in occurrences:
            if len(occurrence.definitions) > 1:
                result[target_fingerprint(occurrence.definitions)] = occurrence.definitions
    return result


def collect_pages(app: Any) -> Iterator[tuple[str, dict[str, Any], str]]:
    """Batch-write the eager source corpus during additional-page collection.

    Calling Sphinx's full theme context pipeline once per source made a real
    stdlib/dependency corpus prohibitively slow.  These pages intentionally
    use a minimal Hackage-style shell, so writing them directly is both more
    faithful and orders of magnitude faster.  Domain index pages remain native
    Sphinx additional pages.
    """
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if snapshot is None or app.builder.name not in SUPPORTED_BUILDERS:
        return
    prefix = app.config.moonbit_semantic_source_prefix.strip("/")
    source_items = sorted(snapshot.sources.values(), key=lambda source: source_pagename(prefix, source))
    index_rows = []
    for source in source_items:
        pagename = source_pagename(prefix, source)
        resolve = lambda occurrence, page=pagename: _target_href(app, page, occurrence)
        if source.literate:
            body = render_literate(app, source, pagename, resolve)
            if body is None:
                # Fail closed semantically while retaining all prose/source.
                body = '<article class="mbt-literate-fallback"><pre>' + escape(snapshot.source_text(source)) + "</pre></article>"
        else:
            body = _render_pure_source(app, source, pagename)
        title = source.title or source.path
        index_uri = app.builder.get_relative_uri(f"{prefix}/index", pagename)
        index_rows.append(f'<li><a href="{escape(index_uri, quote=True)}">{escape(title)}</a></li>')
        _write_page(app, pagename, title, body, source)

    index_body = (
        '<main class="mbt-source-index" data-mbt-semantic-source-index="true">'
        "<h1>MoonBit source</h1><ul>" + "".join(index_rows) + "</ul></main>"
    )
    index_page = f"{prefix}/index"
    _write_page(app, index_page, "MoonBit source", index_body)

    for digest, targets in sorted(_target_sets(snapshot).items()):
        pagename = f"{prefix}/_targets/{digest}"
        rows = []
        for target in sorted(targets, key=lambda item: (item.source_id, item.selection_range)):
            source = snapshot.sources[target.source_id]
            target_page = source_pagename(prefix, source)
            uri = app.builder.get_relative_uri(pagename, target_page)
            anchor = symbol_anchor(target.symbol_id) if target.symbol_id and target.symbol_id in snapshot.symbols else f"L{_source_line(snapshot, target)}"
            label = snapshot.symbols[target.symbol_id].qualified_name or snapshot.symbols[target.symbol_id].name if target.symbol_id in snapshot.symbols else f"{source.path}:{_source_line(snapshot, target)}"
            rows.append(f'<li><a href="{escape(uri + "#" + anchor, quote=True)}">{escape(label)}</a></li>')
        body = '<main class="mbt-target-set"><h1>Possible definitions</h1><ul>' + "".join(rows) + "</ul></main>"
        _write_page(app, pagename, "Possible definitions", body)
    return
    yield  # pragma: no cover - keeps the Sphinx event's generator contract


def get_outdated(app: Any, env: Any, added: set[str], changed: set[str], removed: set[str]) -> list[str]:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if snapshot is None:
        return []
    old = getattr(env, "moonbit_semantic_corpus_digest", None)
    env.moonbit_semantic_corpus_digest = snapshot.corpus_digest
    if old != snapshot.corpus_digest:
        # The payload filename is content-addressed and semantic overlays may
        # also have changed, so every document must be rewritten to reference
        # the new asset and occurrence set.
        found_docs = sorted(getattr(env, "found_docs", ()))
        return found_docs or [app.config.root_doc]
    # Additional pages are not docnames, so force one write sentinel if their
    # output was externally removed between incremental builds.
    prefix = app.config.moonbit_semantic_source_prefix.strip("/")
    pages = [f"{prefix}/index"]
    pages.extend(source_pagename(prefix, source) for source in snapshot.sources.values())
    pages.extend(f"{prefix}/_targets/{digest}" for digest in _target_sets(snapshot))
    expected = [Path(app.builder.get_outfilename(page)) for page in pages]
    static = Path(app.outdir) / "_static" / "moonbit-semantic"
    expected.extend(
        static / name
        for name in (
            "moonbit-semantic.css",
            app._moonbit_semantic_hover_script,
            "moonbit-semantic.js",
            "hovers.json",
        )
    )
    for asset in snapshot.assets.values():
        expected.append(static / "assets" / asset.blob_digest.removeprefix("sha256:") / asset.path.rsplit("/", 1)[-1])
    return [app.config.root_doc] if any(not path.is_file() for path in expected) else []


def on_env_purge_doc(app: Any, env: Any, docname: str) -> None:
    env.get_domain("mbtsem").clear_doc(docname)


def on_env_merge_info(app: Any, env: Any, docnames: list[str], other: Any) -> None:
    other_data = getattr(other, "domaindata", {}).get("mbtsem", {})
    env.get_domain("mbtsem").merge_domaindata(docnames, other_data)


def on_env_check_consistency(app: Any, env: Any) -> None:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if snapshot is None:
        return
    pages = [source_pagename(app.config.moonbit_semantic_source_prefix, source) for source in snapshot.sources.values()]
    if len(set(pages)) != len(pages):
        raise ExtensionError("MoonBit semantic snapshot has colliding source page routes")


def _atomic_write_text(path: Path, content: str) -> None:
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    try:
        temporary.write_text(content, encoding="utf-8")
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def _write_assets(app: Any, exception: Exception | None) -> None:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if exception is not None or snapshot is None or app.builder.name not in SUPPORTED_BUILDERS:
        return
    destination = Path(app.outdir) / "_static" / "moonbit-semantic"
    destination.mkdir(parents=True, exist_ok=True)
    package = Path(__file__).parent
    for name in ("moonbit-semantic.css", "moonbit-semantic.js"):
        shutil.copyfile(package / "static" / name, destination / name)
    payload = _hover_payload(snapshot)
    script_payload = payload.replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    _atomic_write_text(destination / "hovers.json", payload)
    _atomic_write_text(
        destination / app._moonbit_semantic_hover_script,
        "globalThis.__moonbitSemanticHoverPayloads=" + script_payload + ";\n",
    )
    for asset in snapshot.assets.values():
        target = destination / "assets" / asset.blob_digest.removeprefix("sha256:") / asset.path.rsplit("/", 1)[-1]
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(snapshot.asset_bytes(asset))


def _validate_outputs(app: Any, exception: Exception | None) -> None:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if exception is not None or snapshot is None or app.builder.name not in SUPPORTED_BUILDERS:
        return
    prefix = app.config.moonbit_semantic_source_prefix.strip("/")
    planned = [f"{prefix}/index"]
    planned.extend(source_pagename(prefix, source) for source in snapshot.sources.values())
    planned.extend(f"{prefix}/_targets/{digest}" for digest in _target_sets(snapshot))
    missing = []
    for page in planned:
        output = Path(app.builder.get_outfilename(page))
        if not output.is_file():
            missing.append(page)
    if missing:
        message = f"MoonBit semantic build omitted {len(missing)} source pages"
        if app.config.moonbit_semantic_required:
            raise ExtensionError(message)
        LOGGER.warning(message)


def _cleanup_stale_outputs(app: Any, exception: Exception | None) -> None:
    snapshot = getattr(app, "_moonbit_semantic_snapshot", None)
    if exception is not None or snapshot is None or app.builder.name not in SUPPORTED_BUILDERS:
        return
    prefix = app.config.moonbit_semantic_source_prefix.strip("/")
    pages = [f"{prefix}/index"]
    pages.extend(source_pagename(prefix, source) for source in snapshot.sources.values())
    pages.extend(f"{prefix}/_targets/{digest}" for digest in _target_sets(snapshot))
    expected_pages = {Path(app.builder.get_outfilename(page)).resolve() for page in pages}
    page_root = (Path(app.outdir) / prefix).resolve()
    if page_root.is_dir():
        for output in page_root.rglob("*.html"):
            if output.resolve() not in expected_pages:
                output.unlink()

    asset_root = Path(app.outdir) / "_static" / "moonbit-semantic" / "assets"
    expected_assets = {
        (asset_root / asset.blob_digest.removeprefix("sha256:") / asset.path.rsplit("/", 1)[-1]).resolve()
        for asset in snapshot.assets.values()
    }
    if asset_root.is_dir():
        for output in asset_root.rglob("*"):
            if output.is_file() and output.resolve() not in expected_assets:
                output.unlink()

    static_root = Path(app.outdir) / "_static" / "moonbit-semantic"
    for output in static_root.glob("hovers*.js"):
        if output.name != app._moonbit_semantic_hover_script:
            output.unlink()


def on_build_finished(app: Any, exception: Exception | None) -> None:
    _write_assets(app, exception)
    _validate_outputs(app, exception)
    _cleanup_stale_outputs(app, exception)
