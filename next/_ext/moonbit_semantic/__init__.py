"""Static MoonBit Hover and Go-to-definition for Sphinx."""

from __future__ import annotations

from typing import Any

from .lifecycle import get_outdated, on_build_finished, on_builder_inited
from .nodes import setup_block_semantics


def setup(app: Any) -> dict[str, Any]:
    app.add_config_value("moonbit_semantic_snapshot", None, "env", types=(str, type(None)))
    app.add_config_value("moonbit_semantic_required", False, "env", types=(bool,))
    # MyST creates ``env.myst_config`` during its normal setup.  Render Hover
    # Markdown afterwards so the isolated GFM profile can safely derive from it.
    app.connect("builder-inited", on_builder_inited, priority=600)
    app.connect("env-get-outdated", get_outdated)
    app.connect("build-finished", on_build_finished)
    setup_block_semantics(app)
    return {
        "version": "0.2.0",
        "env_version": 2,
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
