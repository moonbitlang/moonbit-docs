# MoonBit Documentation Examples

Use this reference for runnable examples under `next/sources/`, excluding
`next/sources/error_codes/`.

## Relevant paths

- `next/sources/<example>/moon.mod.json`: example module root.
- `next/sources/<example>/**/moon.pkg.json`: package configuration.
- `next/sources/<example>/**/*.mbt`: MoonBit source files.
- `next/sources/single-file/README.mbt.md`: single-file example checked in
  single-file mode.
- `scripts/check-document.py`: repo-level example checker.

## Workflow

1. Locate the example project that backs the docs section.
2. Preserve the existing module/package layout unless the task requires a new
   example.
3. Prefer small, clear examples over clever abstractions.
4. Keep docs snippets and runnable source files consistent.
5. Do not handle `next/sources/error_codes/` here; use `error-docs.md`.
6. Avoid broad `moon fmt` runs. Format only files you intentionally touched when
   formatting is necessary, so example updates stay reviewable.

## Validation

Run repo-level Python commands from the repository root.

- All non-error-code examples: `just check-docs`
- If `just` is unavailable: `python3 scripts/check-document.py`
- Targeted check from an example root:
  - `moon check --deny-warn --target all`
  - `moon test --deny-warn --target all`
- Examples named `async` and `cli-quickstart` are checked with the native target
  by the repo script.
- Single-file example:
  - `cd next/sources/single-file && moon check README.mbt.md`
  - `cd next/sources/single-file && moon test README.mbt.md`

## Notes

- The repo script skips hidden directories, `target`, and `error_codes`.
- It assumes MoonBit dependencies are already resolved.
- Keep warning-free examples unless the example intentionally demonstrates an
  error through the error-code workflow.
