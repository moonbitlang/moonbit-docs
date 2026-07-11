from __future__ import annotations

import pickle
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.moonbit_semantic.inventory import (
    PackageOwnership,
    metadata_package_ownership,
)


def _touch(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fn sample() -> Unit {}\n", encoding="utf-8")
    return path


def test_package_records_and_all_dependency_kinds_are_context_local(tmp_path: Path) -> None:
    source = tmp_path / "app"
    local = _touch(source / "src/cli/main.mbt")
    local_test = _touch(source / "src/cli/main_test.mbt")
    core = _touch(source / ".mooncakes/moonbitlang/core/cmp/cmp.mbt")
    async_file = _touch(source / ".mooncakes/moonbitlang/async/http/server.mbt")
    test_dep = _touch(source / ".mooncakes/vendor/testing/assert.mbt")
    metadata = {
        "source_dir": str(source),
        "packages": [
            {
                "root": "example/app",
                "rel": "cli",
                "root-path": "src/cli",
                "files": {"main.mbt": {}},
                "test-files": {str(local_test): {}},
                "deps": [
                    {
                        "path": "moonbitlang/core/cmp",
                        "fspath": ".mooncakes/moonbitlang/core/cmp",
                    }
                ],
                "wbtest-deps": [
                    {
                        "path": "moonbitlang/async/http",
                        "fspath": ".mooncakes/moonbitlang/async/http",
                    }
                ],
                "test-deps": [
                    {
                        "path": "vendor/testing",
                        "fspath": ".mooncakes/vendor/testing",
                    }
                ],
            }
        ],
    }

    ownership = metadata_package_ownership(metadata)

    assert ownership.resolve(local) == "example/app/cli"
    assert ownership.resolve(local_test) == "example/app/cli"
    assert ownership.resolve(core) == "moonbitlang/core/cmp"
    assert ownership.resolve(async_file) == "moonbitlang/async/http"
    assert ownership.resolve_location(async_file) == (
        "moonbitlang/async/http",
        "server.mbt",
    )
    assert ownership.resolve(test_dep) == "vendor/testing"
    assert all(path != local_test.resolve() for path, _package in ownership.file_owners)

    other_context_file = _touch(tmp_path / "other-context/src/foreign.mbt")
    assert ownership.resolve(other_context_file) is None


def test_exact_production_file_precedes_longest_root_ancestor(tmp_path: Path) -> None:
    outer = tmp_path / "module/src"
    inner = outer / "nested"
    exact_outer_file = _touch(inner / "generated.mbt")
    ordinary_inner_file = _touch(inner / "ordinary.mbt")
    metadata = {
        "packages": [
            {
                "root": "example/module",
                "rel": "outer",
                "root-path": str(outer),
                "files": {str(exact_outer_file): {}},
            },
            {
                "root": "example/module",
                "rel": "inner",
                "root-path": str(inner),
                "files": {},
            },
        ]
    }

    ownership = metadata_package_ownership(metadata)

    assert ownership.resolve(exact_outer_file) == "example/module/outer"
    assert ownership.resolve_location(exact_outer_file) == (
        "example/module/outer",
        "nested/generated.mbt",
    )
    assert ownership.resolve(ordinary_inner_file) == "example/module/inner"


def test_ambiguous_exact_file_or_longest_root_fails_closed(tmp_path: Path) -> None:
    shared = tmp_path / "shared"
    exact = _touch(shared / "exact.mbt")
    unlisted = _touch(shared / "unlisted.mbt")
    metadata = {
        "packages": [
            {
                "root": "first/module",
                "rel": "pkg",
                "root-path": str(shared),
                "files": {str(exact): {}},
            },
            {
                "root": "second/module",
                "rel": "pkg",
                "root-path": str(shared),
                "files": {str(exact): {}},
            },
        ]
    }

    ownership = metadata_package_ownership(metadata)

    assert ownership.resolve(exact) is None
    assert ownership.resolve(unlisted) is None


def test_realpaths_and_pickle_round_trip_are_stable(tmp_path: Path) -> None:
    physical = tmp_path / "physical/package"
    target = _touch(physical / "value.mbt")
    alias = tmp_path / "alias"
    alias.symlink_to(physical, target_is_directory=True)
    metadata = {
        "packages": [
            {
                "root": "example/package@unparsed",
                "rel": "",
                "root-path": str(alias),
                "files": {str(alias / "value.mbt"): {}},
            }
        ]
    }

    ownership = metadata_package_ownership(metadata)
    restored = pickle.loads(pickle.dumps(ownership))

    assert isinstance(restored, PackageOwnership)
    assert restored == ownership
    assert restored.resolve(target) == "example/package@unparsed"
    assert restored.resolve(alias / "value.mbt") == "example/package@unparsed"


def test_separate_metadata_instances_never_share_package_identity(tmp_path: Path) -> None:
    shared = tmp_path / "shared"
    target = _touch(shared / "value.mbt")
    first = metadata_package_ownership(
        {
            "packages": [
                {
                    "root": "context/one",
                    "rel": "",
                    "root-path": str(shared),
                    "files": {},
                }
            ]
        }
    )
    second = metadata_package_ownership(
        {
            "packages": [
                {
                    "root": "context/two",
                    "rel": "",
                    "root-path": str(shared),
                    "files": {},
                }
            ]
        }
    )

    assert first.resolve(target) == "context/one"
    assert second.resolve(target) == "context/two"


def test_dependency_path_and_fspath_can_fall_back_to_package_records(tmp_path: Path) -> None:
    source = tmp_path / "source"
    by_path_root = source / "by-path"
    by_root_root = source / "by-root"
    by_path = _touch(by_path_root / "path.mbt")
    by_root = _touch(by_root_root / "root.mbt")
    metadata = {
        "packages": [
            {
                "root": "dependency/by-path",
                "rel": "",
                "root-path": str(by_path_root),
                "files": {},
                "deps": [{"path": "dependency/by-root", "fspath": str(by_root_root)}],
                "wbtest-deps": [{"path": "dependency/by-path"}],
                "test-deps": [{"fspath": str(by_root_root)}],
            },
            {
                "root": "dependency/by-root",
                "rel": "",
                "root-path": str(by_root_root),
                "files": {},
            },
        ]
    }

    ownership = metadata_package_ownership(metadata)

    assert ownership.resolve(by_path) == "dependency/by-path"
    assert ownership.resolve(by_root) == "dependency/by-root"
