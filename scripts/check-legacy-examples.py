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
        check_targets = "all"
        test_targets = "all"
        if example.name == "wasi-http":
            check_targets = "wasm"
            test_targets = "wasm"
        elif example.name in ["tetris", "mandelbrot", "koch_snowflake", "game_of_life"]:
            check_targets = "wasm-gc"
            test_targets = "wasm-gc"
        elif example.name == "snake":
            check_targets = "wasm,wasm-gc,js"
            test_targets = None

        print(f"Processing {example.name}")
        try:
            subprocess.run(
                ["moon", "check", "--target", check_targets],
                cwd=example,
                check=True,
            )
            if test_targets is not None:
                subprocess.run(
                    ["moon", "test", "--target", test_targets],
                    cwd=example,
                    check=True,
                )
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
