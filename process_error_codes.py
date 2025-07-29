#!/usr/bin/env python3

import os
import re
import subprocess
import sys

# Path to the error codes directory
error_codes_dir = "next/language/error_codes"
sources_dir = "next/sources/language"

def extract_code_blocks(content):
    """Extract MoonBit code blocks from markdown content."""
    code_blocks = []
    pattern = r'```moonbit\n(.*?)\n```'
    matches = re.finditer(pattern, content, re.DOTALL)
    for match in matches:
        code_blocks.append(match.group(1))
    return code_blocks

def check_moonbit_code(code, filename_suffix=""):
    """Check MoonBit code and return error/warning information."""
    test_file = f"{sources_dir}/test_auto{filename_suffix}.mbt"
    try:
        with open(test_file, 'w') as f:
            f.write(code)
        
        result = subprocess.run(
            ["moonc", "check", test_file, "-error-format=json"],
            cwd=sources_dir,
            capture_output=True,
            text=True
        )
        
        # Clean up
        os.remove(test_file)
        
        return result.stderr, result.returncode
    except Exception as e:
        # Clean up on error
        if os.path.exists(test_file):
            os.remove(test_file)
        return str(e), -1

def extract_error_code_from_json(stderr_output):
    """Extract error codes from moonc JSON output."""
    error_codes = []
    for line in stderr_output.split('\n'):
        if '"error_code":' in line:
            match = re.search(r'"error_code":(\d+)', line)
            if match:
                error_codes.append(int(match.group(1)))
    return error_codes

def process_error_file(error_file):
    """Process a single error code file."""
    print(f"Processing {error_file}...")
    
    try:
        with open(f"{error_codes_dir}/{error_file}", 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {error_file}: {e}")
        return False
    
    # Extract expected error code from filename (e.g., "E0001.md" -> 1)
    expected_code_match = re.match(r'E(\d+)\.md', error_file)
    if not expected_code_match:
        print(f"Invalid filename format: {error_file}")
        return False
    
    expected_code = int(expected_code_match.group(1))
    
    # Extract code blocks
    code_blocks = extract_code_blocks(content)
    if not code_blocks:
        print(f"No code blocks found in {error_file}")
        return False
    
    # Find the first code block that produces the expected error
    example_code = None
    suggestion_code = None
    
    for i, code_block in enumerate(code_blocks):
        stderr, returncode = check_moonbit_code(code_block, f"_{i}")
        error_codes = extract_error_code_from_json(stderr)
        
        if expected_code in error_codes and example_code is None:
            # This code block produces the expected error - use it as example
            example_code = code_block
        elif expected_code not in error_codes and suggestion_code is None:
            # This might be a fix - use it as suggestion (but verify it's reasonable)
            suggestion_code = code_block
    
    # If we couldn't find an example, use the first code block
    if example_code is None and code_blocks:
        example_code = code_blocks[0]
    
    # If we couldn't find a suggestion, create a simple one based on the example
    if suggestion_code is None and example_code:
        # Try some common fixes
        suggestion_candidates = [
            # Add pub to functions/types
            re.sub(r'^(fn|type|struct|enum|trait)', r'pub \1', example_code, flags=re.MULTILINE),
            # Replace main with init
            re.sub(r'fn main\s*\{', 'fn init {', example_code),
            # Add ignore pattern
            example_code + "\n\nfn init {\n  // Usage to avoid warnings\n}"
        ]
        
        for candidate in suggestion_candidates:
            stderr, returncode = check_moonbit_code(candidate)
            error_codes = extract_error_code_from_json(stderr)
            if expected_code not in error_codes:
                suggestion_code = candidate
                break
    
    # Create the files
    base_name = error_file.replace('.md', '')
    
    # Write example file
    if example_code:
        example_file = f"{error_codes_dir}/{base_name}_example.mbt.md"
        with open(example_file, 'w') as f:
            f.write(f"```moonbit\n{example_code}\n```\n")
        print(f"Created {base_name}_example.mbt.md")
    
    # Write suggestion file
    if suggestion_code:
        suggestion_file = f"{error_codes_dir}/{base_name}_suggestion.mbt.md"
        with open(suggestion_file, 'w') as f:
            f.write(f"```moonbit\n{suggestion_code}\n```\n")
        print(f"Created {base_name}_suggestion.mbt.md")
    
    # Update original file
    try:
        # Find erroneous example section and replace with include
        updated_content = re.sub(
            r'## Erroneous example\s*\n\n```moonbit\n.*?\n```',
            f'## Erroneous example\n\n```{{include}} {base_name}_example.mbt.md\n```',
            content,
            flags=re.DOTALL
        )
        
        # Find and update suggestion sections with code blocks
        suggestion_pattern = r'(```moonbit\n.*?\n```)'
        def replace_suggestion(match):
            return f'```{{include}} {base_name}_suggestion.mbt.md\n```'
        
        # Only replace the first occurrence in suggestion section
        suggestion_start = updated_content.find('## Suggestion')
        if suggestion_start != -1:
            before_suggestion = updated_content[:suggestion_start]
            suggestion_part = updated_content[suggestion_start:]
            suggestion_part = re.sub(suggestion_pattern, replace_suggestion, suggestion_part, count=1, flags=re.DOTALL)
            updated_content = before_suggestion + suggestion_part
        
        with open(f"{error_codes_dir}/{error_file}", 'w') as f:
            f.write(updated_content)
        
        print(f"Updated {error_file}")
    except Exception as e:
        print(f"Error updating {error_file}: {e}")
        return False
    
    return True

def main():
    # Get list of error files that haven't been processed yet
    error_files = []
    for filename in os.listdir(error_codes_dir):
        if filename.startswith('E') and filename.endswith('.md'):
            # Check if already processed
            base_name = filename.replace('.md', '')
            example_file = f"{error_codes_dir}/{base_name}_example.mbt.md"
            if not os.path.exists(example_file):
                error_files.append(filename)
    
    error_files.sort()
    
    print(f"Found {len(error_files)} files to process")
    
    processed = 0
    failed = 0
    
    for error_file in error_files:
        if process_error_file(error_file):
            processed += 1
        else:
            failed += 1
        
        print(f"Progress: {processed + failed}/{len(error_files)}")
    
    print(f"\nProcessing complete!")
    print(f"Processed: {processed}")
    print(f"Failed: {failed}")
    print(f"Total: {len(error_files)}")

if __name__ == "__main__":
    main()