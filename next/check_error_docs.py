#!/usr/bin/env python3
"""Check error code documentation script"""

import argparse
import os
import subprocess
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
ERROR_CODES_DIR = BASE_DIR / 'language/error_codes'
ERROR_CODES_SOURCE_DIR = BASE_DIR / 'sources/error_codes'
RUN_ONLY_ERROR_CODES = {
    # The compiler no longer exposes warning 58 / unused_non_capturing, but
    # the documentation snippets should still stay runnable.
    '0058',
}
SKIPPED_ERROR_CODES = {
    # Current MoonBit does not emit this warning.
    '0016',
    # Reproducing E0033 requires an extremely long source segment to exceed the
    # compiler's internal line/column limits, so we do not monitor it with a
    # small checked example project.
    '0033',
    # These compatibility diagnostics are no longer emitted directly, or are
    # routed through newer, more specific diagnostics.
    '0045',
    '0047',
    '4054',
    '4066',
    '4092',
    # These internal diagnostics are not meant to appear as independent
    # user-facing errors.
    '1000',
    '1001',
    # Legacy or build-system configuration parsing happens before ordinary
    # source-level diagnostic rendering is available to the checker.
    '3017',
    '4192',
    '4212',
    # Current MoonBit reports missing infix operator methods through more
    # specific diagnostics, so E4016 does not have a stable source repro.
    '4016',
    # These package-loading diagnostics depend on missing or malformed internal
    # build artifacts rather than ordinary MoonBit source projects.
    '4047',
    '4048',
    '4049',
    # Current MoonBit reports this source pattern through newer diagnostics.
    '4120',
}


def example_status(error_code):
    """Return whether examples for this error code are fully monitored."""
    if error_code in SKIPPED_ERROR_CODES:
        return 'skipped'

    error_path = ERROR_CODES_SOURCE_DIR / f"{error_code}_error"
    fixed_path = ERROR_CODES_SOURCE_DIR / f"{error_code}_fixed"
    has_error = is_moon_project(error_path)
    has_fixed = is_moon_project(fixed_path)

    if has_error and has_fixed:
        return 'full'
    if has_error or has_fixed:
        return 'partial'
    return 'missing'


def is_moon_project(path: Path) -> bool:
    """Return True if the path looks like a Moon project root."""
    return (path / 'moon.mod.json').exists()


def diagnostic_codes(output):
    """Return all numbered compiler diagnostics in moon output."""
    return re.findall(r'(?:Warning|Error): \[(\d{4})\]', output)


def has_error_code(output, error_code):
    """Return True if moon output contains this error diagnostic."""
    return bool(re.search(rf'Error: \[{error_code}\]', output))


def run_moon_test(file_path, error_code=None):
    """Execute moon check command and return results"""
    try:
        if not is_moon_project(Path(file_path)):
            return True
        subprocess.run(['moon', 'clean'], cwd=file_path)
        result = subprocess.run(
            ['moon', 'check'],
            capture_output=True,
            text=True,
            env={**os.environ, 'NO_COLOR': '1'},
            cwd=file_path,
        )

        output = result.stdout + result.stderr
        codes = diagnostic_codes(output)

        if error_code:
            error_code_padded = error_code.zfill(4)
            has_only_expected = codes and all(
                code == error_code_padded for code in codes)
            if int(error_code) < 3000:
                # Expect warning or error
                has_expected = has_only_expected
            else:
                # Expect error - command should fail. Error recovery can report
                # cascading diagnostics, so only warning-code examples are
                # strict about emitting no other diagnostic codes.
                has_expected = result.returncode != 0 and \
                    has_error_code(output, error_code_padded)
        else:
            # Expect no warnings or errors
            has_expected = not codes and result.returncode == 0

        return has_expected

    except Exception:
        return False


def check_error_code(error_code):
    """Check specific error code documentation"""
    if error_code in SKIPPED_ERROR_CODES:
        return True

    error_path = ERROR_CODES_SOURCE_DIR / f"{error_code}_error"
    fixed_path = ERROR_CODES_SOURCE_DIR / f"{error_code}_fixed"

    if example_status(error_code) == 'missing':
        return True

    if error_code in RUN_ONLY_ERROR_CODES:
        return run_moon_test(str(error_path)) and run_moon_test(str(fixed_path))

    # Test error case should produce warning/error
    error_ok = run_moon_test(str(error_path), error_code)

    # Test fixed case should have no warnings/errors
    fixed_ok = run_moon_test(str(fixed_path))

    return error_ok and fixed_ok


def get_all_error_codes():
    """Get all error code list"""
    error_codes_path = ERROR_CODES_DIR
    if not error_codes_path.exists():
        return []

    error_codes = []
    for file in error_codes_path.iterdir():
        if file.is_file() and file.name.startswith('E') and file.name.endswith('.md'):
            match = re.match(r'^E(\d{4})\.md$', file.name)
            if match:
                error_codes.append(match.group(1))

    return sorted(error_codes)


def print_coverage_summary(error_codes):
    """Print example coverage for all known error codes."""
    missing = []
    partial = []
    skipped = []

    for error_code in error_codes:
        status = example_status(error_code)
        if status == 'missing':
            missing.append(error_code)
        elif status == 'partial':
            partial.append(error_code)
        elif status == 'skipped':
            skipped.append(error_code)

    total = len(error_codes)
    full = total - len(missing) - len(partial) - len(skipped)
    print(
        f"Coverage: {full} full, {len(partial)} partial, "
        f"{len(missing)} missing, {len(skipped)} skipped, {total} total")

    if partial:
        print(f"PARTIAL: {', '.join(partial)}")

    if missing:
        print(f"MISSING: {', '.join(missing)}")

    if skipped:
        print(f"SKIPPED: {', '.join(skipped)}")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Check error code documentation')
    parser.add_argument(
        'target', help='Error code to check or "all" for all codes')
    parser.add_argument(
        '--require-examples',
        action='store_true',
        help='fail if any error code is missing monitored examples')
    args = parser.parse_args()

    if args.target == 'all':
        error_codes = get_all_error_codes()
        if not error_codes:
            print('No error codes found')
            return 1

        failed = []
        for error_code in error_codes:
            if not check_error_code(error_code):
                failed.append(error_code)

        total = len(error_codes)
        passed = total - len(failed)

        if failed:
            print(f"FAILED: {', '.join(failed)}")

        print(f"Results: {passed} passed, {len(failed)} failed, {total} total")
        print_coverage_summary(error_codes)

        if args.require_examples:
            incomplete = [
                error_code for error_code in error_codes
                if example_status(error_code) != 'full'
                and error_code not in SKIPPED_ERROR_CODES
            ]
            if incomplete:
                print(f"INCOMPLETE: {', '.join(incomplete)}")

            return 1 if failed or incomplete else 0

        return 1 if failed else 0

    else:
        if not re.match(r'^\d+$', args.target):
            print('Error: Invalid error code format, should be like 0001')
            return 1

        if (
            args.require_examples
            and args.target not in SKIPPED_ERROR_CODES
            and example_status(args.target) != 'full'
        ):
            print(f"INCOMPLETE: {args.target}")
            return 1

        success = check_error_code(args.target)
        status = "PASS" if success else "FAIL"
        print(f"{status}: {args.target}")
        return 0 if success else 1


if __name__ == '__main__':
    exit(main())
