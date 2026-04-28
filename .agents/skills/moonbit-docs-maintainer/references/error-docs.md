# Error-Code Documentation

Use this reference for compiler error-code docs and their MoonBit examples.
The migration is not complete yet: the target state is for each documented
error code to have both an error example and a fixed example, but some codes may
currently have prose only.

## Relevant paths

- `next/language/error_codes/E0001.md`: prose documentation for one error code.
- `next/sources/error_codes/0001_error/`: example expected to trigger the code.
- `next/sources/error_codes/0001_fixed/`: fixed example expected to pass without
  warnings or errors.
- `next/check_error_docs.py`: validation script.

## Workflow

1. Keep each prose page aligned with any migrated examples for that code.
2. Use four-digit codes in file and directory names.
3. For codes below `3000`, the error example may produce a warning or an error.
4. For codes `3000` and above, the error example must fail with that error.
5. The fixed example must pass `moon check` with no warnings or errors.
6. Avoid broad `moon fmt` runs. Format only the error-code example files you
   intentionally touched when formatting is necessary.
7. When migrating or adding examples, prefer adding both `<code>_error/` and
   `<code>_fixed/` as independent MoonBit projects with their own
   `moon.mod.json`.

## Validation

Run the checker from the repository root.

- One code: `just check-error 0001`
- All codes: `just check-errors`
- If `just` is unavailable:
  - `python3 next/check_error_docs.py 0001`
  - `python3 next/check_error_docs.py all`

The checker runs `moon clean` and `moon check` inside each example project with
`NO_COLOR=1`, then matches `Warning: [0001]` or `Error: [0001]` patterns.
If a code has neither an `_error` nor a `_fixed` project yet, the checker treats
it as not migrated and skips it successfully.

## Notes

- If adding a new error-code page, add both `_error` and `_fixed` source
  directories when examples are possible. If an example is not practical yet,
  leave the prose accurate and do not invent a brittle sample.
- Do not assume missing example directories are a failure; this docs area is
  still being migrated.
- If the compiler output changed, update the examples first and then adjust the
  prose.
- Do not use `scripts/check-document.py` for error-code examples; it explicitly
  skips them.
