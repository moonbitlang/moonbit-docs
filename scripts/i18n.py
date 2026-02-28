#!/usr/bin/env python3
import argparse
import os
import subprocess
from pathlib import Path


def run(cmd, cwd=None, dry_run=False, env=None) -> None:
    if dry_run:
        print(f"DRY RUN: {' '.join(cmd)}")
        return
    subprocess.run(cmd, cwd=cwd, check=True, env=env)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Sphinx i18n helper (gettext + sphinx-intl update)",
    )
    parser.add_argument("--next-dir", type=Path, default=Path("next"))
    parser.add_argument("--locale", default="zh_CN")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("cmd", choices=["gettext", "sync", "all"])
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    next_venv_python = args.next_dir / ".venv" / "bin" / "python"

    if args.cmd in ("gettext", "all"):
        env = os.environ.copy()
        if "SPHINXBUILD" not in env and next_venv_python.exists():
            env["SPHINXBUILD"] = "./.venv/bin/python -m sphinx"
        run(["make", "gettext"], cwd=args.next_dir, dry_run=args.dry_run, env=env)

    if args.cmd in ("sync", "all"):
        pot_dir = args.next_dir / "_build" / "gettext"
        cmd = ["sphinx-intl"]
        if next_venv_python.exists():
            cmd = [str(next_venv_python), "-m", "sphinx_intl"]
        run(
            cmd + ["update", "-p", str(pot_dir), "-l", args.locale],
            cwd=args.next_dir,
            dry_run=args.dry_run,
        )


if __name__ == "__main__":
    main()
