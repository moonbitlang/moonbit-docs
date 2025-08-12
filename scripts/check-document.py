#!/usr/bin/env python3
import sys
import subprocess
import argparse
from pathlib import Path


def run_cmd(cmd, cwd=None):
    """Run command and return success status."""
    try:
        subprocess.run(cmd, cwd=cwd, check=True)
        return True
    except subprocess.CalledProcessError:
        print(f"Failed: {' '.join(cmd)} in {cwd}")
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", required=True,
                        choices=["wasm", "wasm-gc", "js"])
    args = parser.parse_args()

    # Process directories
    failed = []
    for dir_path in Path("next/sources").iterdir():
        if not dir_path.is_dir():
            continue

        # Skip error codes; they should be handled with another script
        if dir_path.name == "error_codes":
            continue
        # Skip async for non-js backends
        if dir_path.name == "async" and args.backend != "js":
            continue

        print(f"Processing {dir_path}")

        # Run moon commands
        commands = [
            ["moon", "install"],
            ["moon", "check", "--deny-warn", "--target", args.backend],
            ["moon", "test", "--target", args.backend]
        ]

        if not all(run_cmd(cmd, dir_path) for cmd in commands):
            failed.append(str(dir_path))

    # Report results
    if failed:
        print("\nFailed directories:")
        for d in failed:
            print(d)
        return 1

    # Show file sizes
    target = Path("target")
    if target.exists():
        for pattern in ["*.wasm", "*.js"]:
            files = list(target.rglob(pattern))
            if files:
                print(f"\n{pattern.upper()} files:")
                for f in files:
                    print(f"{f} ({f.stat().st_size} bytes)")

    print("\nAll checks passed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
