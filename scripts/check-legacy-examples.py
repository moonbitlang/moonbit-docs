#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path


def main():
    root = Path(__file__).parent.parent
    examples_dir = root / "legacy" / "examples"

    failed = []
    for example in sorted(examples_dir.iterdir()):
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
            print(f"✓ {example.name}")
        except subprocess.CalledProcessError:
            print(f"✗ {example.name}")
            failed.append(example.name)

    if failed:
        print(f"\nFailed: {', '.join(failed)}")
        sys.exit(1)
    else:
        print("\nAll examples passed!")


if __name__ == "__main__":
    main()
