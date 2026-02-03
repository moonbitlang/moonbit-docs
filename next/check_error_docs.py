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


def is_moon_project(path: Path) -> bool:
    """Return True if the path looks like a Moon project root."""
    return (path / 'moon.mod.json').exists()


def run_moon_test(file_path, error_code=None):
    """Execute moon check command and return results"""
    try:
        if not is_moon_project(Path(file_path)):
            return True
        subprocess.run(['moon', 'clean', '-C', file_path],)
        result = subprocess.run(
            ['moon', 'check', '-C', file_path],
            capture_output=True,
            text=True,
            env={**os.environ, 'NO_COLOR': '1'}
        )

        output = result.stdout + result.stderr
        has_warnings = bool(re.search(r'Warning: \[\d{4}\]', output))
        has_errors = bool(re.search(r'Error: \[\d{4}\]', output))

        if error_code:
            error_code_padded = error_code.zfill(4)
            if int(error_code) < 3000:
                # Expect warning or error
                warning_pattern = rf'Warning: \[{error_code_padded}\]'
                error_pattern = rf'Error: \[{error_code_padded}\]'
                has_expected = bool(re.search(warning_pattern, output)) or \
                    (result.returncode != 0 and bool(
                        re.search(error_pattern, output)))
            else:
                # Expect error - command should fail
                has_expected = result.returncode != 0 and \
                    bool(re.search(rf'Error: \[{error_code_padded}\]', output))
        else:
            # Expect no warnings or errors
            has_expected = not has_warnings and not has_errors and result.returncode == 0

        return has_expected

    except Exception:
        return False


def check_error_code(error_code):
    """Check specific error code documentation"""
    error_path = ERROR_CODES_SOURCE_DIR / f"{error_code}_error"
    fixed_path = ERROR_CODES_SOURCE_DIR / f"{error_code}_fixed"

    if not error_path.exists() and not fixed_path.exists():
        return True

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


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Check error code documentation')
    parser.add_argument(
        'target', help='Error code to check or "all" for all codes')
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
        return 1 if failed else 0

    else:
        if not re.match(r'^\d+$', args.target):
            print('Error: Invalid error code format, should be like 0001')
            return 1

        success = check_error_code(args.target)
        status = "PASS" if success else "FAIL"
        print(f"{status}: {args.target}")
        return 0 if success else 1


if __name__ == '__main__':
    exit(main())
