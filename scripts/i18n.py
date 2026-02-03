#!/usr/bin/env python3
import argparse
import shutil
import subprocess
from pathlib import Path


def require_tool(name: str) -> None:
    if shutil.which(name) is None:
        raise SystemExit(f"Missing tool: {name}. Please install gettext.")


def run(cmd, cwd=None, dry_run=False) -> None:
    if dry_run:
        print(f"DRY RUN: {' '.join(cmd)}")
        return
    subprocess.run(cmd, cwd=cwd, check=True)


def iter_pots(pot_dir: Path):
    return sorted(pot_dir.rglob("*.pot"))


def iter_pos(po_dir: Path):
    return sorted(po_dir.rglob("*.po"))


def cmd_gettext(args) -> None:
    run(["make", "gettext"], cwd=args.next_dir, dry_run=args.dry_run)


def cmd_dedup(args) -> None:
    require_tool("msguniq")
    po_dir = args.po_dir
    for po in iter_pos(po_dir):
        run(["msguniq", "--use-first", "--output-file", str(po), str(po)], dry_run=args.dry_run)


def cmd_merge(args) -> None:
    require_tool("msgmerge")
    require_tool("msginit")
    pot_dir = args.pot_dir
    po_dir = args.po_dir
    for pot in iter_pots(pot_dir):
        rel = pot.relative_to(pot_dir)
        po = (po_dir / rel).with_suffix(".po")
        po.parent.mkdir(parents=True, exist_ok=True)
        if po.exists():
            run(
                ["msgmerge", "--update", "--no-fuzzy-matching", str(po), str(pot)],
                dry_run=args.dry_run,
            )
        else:
            run(
                [
                    "msginit",
                    "--no-translator",
                    "--input",
                    str(pot),
                    "--locale",
                    args.locale,
                    "--output-file",
                    str(po),
                ],
                dry_run=args.dry_run,
            )


def cmd_sync(args) -> None:
    cmd_dedup(args)
    cmd_merge(args)


def cmd_all(args) -> None:
    cmd_gettext(args)
    cmd_sync(args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Sphinx i18n helper (gettext + msgmerge + msguniq)",
    )
    parser.add_argument("--next-dir", type=Path, default=Path("next"))
    parser.add_argument("--locale", default="zh_CN")
    parser.add_argument(
        "--pot-dir",
        type=Path,
        default=Path("next/_build/gettext"),
        help="Directory with .pot files",
    )
    parser.add_argument(
        "--po-dir",
        type=Path,
        default=Path("next/locales/zh_CN/LC_MESSAGES"),
        help="Directory with .po files",
    )
    parser.add_argument("--dry-run", action="store_true")

    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("gettext", help="Run make gettext in next/").set_defaults(func=cmd_gettext)
    sub.add_parser("dedup", help="Run msguniq over .po files").set_defaults(func=cmd_dedup)
    sub.add_parser("merge", help="Merge .pot into .po files").set_defaults(func=cmd_merge)
    sub.add_parser("sync", help="Dedup then merge").set_defaults(func=cmd_sync)
    sub.add_parser("all", help="gettext then sync").set_defaults(func=cmd_all)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    if args.po_dir == Path("next/locales/zh_CN/LC_MESSAGES") and args.locale != "zh_CN":
        args.po_dir = Path("next/locales") / args.locale / "LC_MESSAGES"
    args.func(args)


if __name__ == "__main__":
    main()
