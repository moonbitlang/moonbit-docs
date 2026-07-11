"""Static MoonBit Hover and Go-to-definition for Sphinx."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from .domain import MoonBitSemanticDomain
from .literate import prepare_literate_doctrees
from .nodes import setup_block_semantics
from .source_pages import (
    collect_pages,
    get_outdated,
    on_build_finished,
    on_builder_inited,
    on_env_check_consistency,
    on_env_merge_info,
    on_env_purge_doc,
)


def _config_inited(app: Any, config: Any) -> None:
    prefix = str(config.moonbit_semantic_source_prefix or "_moonbit-source").strip("/")
    if not prefix or any(part in {".", ".."} for part in prefix.split("/")):
        raise ValueError("moonbit_semantic_source_prefix must be a safe relative URL prefix")
    config.moonbit_semantic_source_prefix = prefix
    templates = str(Path(__file__).parent / "templates")
    if templates not in config.templates_path:
        config.templates_path.insert(0, templates)


def setup(app: Any) -> dict[str, Any]:
    app.add_config_value("moonbit_semantic_snapshot", None, "env", types=(str, type(None)))
    app.add_config_value("moonbit_semantic_required", False, "env", types=(bool,))
    app.add_config_value("moonbit_semantic_source_prefix", "_moonbit-source", "html", types=(str,))
    app.add_domain(MoonBitSemanticDomain)
    app.connect("config-inited", _config_inited)
    app.connect("builder-inited", on_builder_inited)
    app.connect("env-get-outdated", get_outdated)
    app.connect("env-before-read-docs", prepare_literate_doctrees)
    app.connect("env-purge-doc", on_env_purge_doc)
    app.connect("env-merge-info", on_env_merge_info)
    app.connect("env-check-consistency", on_env_check_consistency)
    app.connect("html-collect-pages", collect_pages)
    app.connect("build-finished", on_build_finished)
    setup_block_semantics(app)
    return {
        "version": "0.1.0",
        "env_version": 1,
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
