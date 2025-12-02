#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path


def main():

    failed = []
    for example in sorted(Path("legacy/examples").iterdir()):
        if not example.is_dir() or example.name.startswith('.') or example.name == "target":
            continue

        # Skip wasi-http for non-wasm backends
        targets = "all"
        if example.name == "wasi-http":
            targets = "wasm"

        print(f"Processing {example.name}")
        try:
            subprocess.run(["moon", "install"], cwd=example, check=True)
            subprocess.run(["moon", "check", "--target",
                           targets], cwd=example, check=True)
            subprocess.run(["moon", "test", "--target", targets],
                           cwd=example, check=True)
            print(f"OK: {example.name}")
        except subprocess.CalledProcessError:
            print(f"FAIL: {example.name}")
            failed.append(example.name)

    if failed:
        print(f"\nFailed: {', '.join(failed)}")
        sys.exit(1)
    else:
        print("\nAll examples passed!")


if __name__ == "__main__":
    main()
