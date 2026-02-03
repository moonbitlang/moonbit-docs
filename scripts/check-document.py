#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path


def main():
    # Process directories
    failed = []
    for dir_path in sorted(Path("next/sources").iterdir()):
        if not dir_path.is_dir() or dir_path.name.startswith('.') or dir_path.name == "target":
            continue

        # Skip error codes; they should be handled with another script
        if dir_path.name == "error_codes":
            continue

        # Skip async for non-js backends
        targets = "all"
        if dir_path.name == "async":
            targets = "native"

        print(f"Processing {dir_path}")

        # Run moon commands (no moon install here; assume deps are pre-resolved)
        try:
            subprocess.run(
                ["moon", "check", "--deny-warn", "--target", targets],
                cwd=dir_path,
                check=True,
            )
            subprocess.run(
                ["moon", "test", "--deny-warn", "--target", targets],
                cwd=dir_path,
                check=True,
            )
            print(f"OK: {dir_path.name}")
        except subprocess.CalledProcessError:
            print(f"FAIL: {dir_path.name}")
            failed.append(dir_path.name)

    # Report results
    if failed:
        print(f"\nFailed: {', '.join(failed)}")
        sys.exit(1)
    else:
        print("\nAll examples passed!")


if __name__ == "__main__":
    main()
