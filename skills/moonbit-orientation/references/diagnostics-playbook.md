# Diagnostics Playbook

Use this file before fixing compiler, package, test, or backend failures.

## First pass

1. Preserve the exact command, target, working directory, and diagnostic text.
2. Identify whether the failure comes from `moonc`, `moon`, tests, dependency
   resolution, generated docs, or backend output.
3. Fix the earliest root-cause diagnostic first; later diagnostics may cascade.
4. Inspect local `moon.mod.json`, `moon.pkg.json`, imports, and touched files.
5. Re-run the narrowest command that reproduces the failure.

## Error codes

- If the diagnostic includes `E####`, consult the exact error-code docs when
  available.
- Use `moon check --explain` when available.
- Use the online error index at
  <https://docs.moonbitlang.com/en/latest/language/error_codes/index.html>.
- For a specific code, use the URL pattern
  `https://docs.moonbitlang.com/en/latest/language/error_codes/E####.html`,
  for example
  <https://docs.moonbitlang.com/en/latest/language/error_codes/E0020.html>.
- If you state what an error code means, include the exact `moon check
  --explain` result or the exact error-code URL in the answer.
- Do not assume every error code has a complete runnable example yet.

## Type and method errors

- Check whether the receiver type is the type the method belongs to.
- Check whether a trait implementation is required or imported.
- Check visibility and package boundaries before adding duplicate helpers.
- Avoid defining public methods for foreign types outside the type's package;
  local private methods have narrower use.

## Package and dependency errors

- Inspect module-level dependencies in `moon.mod.json`.
- Inspect package imports and backend settings in `moon.pkg.json`.
- Use `moon tree`, `moon add`, `moon remove`, `moon install`, or `moon update`
  only after confirming the intended dependency change.
- If generated interfaces are stale, `moon info` can help inspect public APIs.

## Test failures

- Determine whether the failure is a compile error, assertion failure, snapshot
  change, backend mismatch, or missing test dependency.
- Prefer `moon test` for the affected package before broader test runs.
- When tests are target-sensitive, include the relevant `--target`.

## Backend errors

- Confirm the selected target: `wasm`, `wasm-gc`, `js`, or `native`.
- Treat `llvm` as nightly-only. If a failure mentions `llvm`, first confirm the
  user is on a nightly toolchain and actually intended to use it.
- Backend-specific interop and output layout should be checked against the
  relevant official docs:
  - FFI: <https://docs.moonbitlang.com/en/latest/language/ffi.html>
  - WebAssembly: <https://docs.moonbitlang.com/en/latest/toolchain/wasm/index.html>
- If code works on one target but not another, inspect backend conditionals,
  package config, FFI declarations, and unsupported APIs.

## Validation commands

- `moon check`: fast compile/type feedback.
- `moon check --target all`: broad target compatibility when supported by the
  project; this does not include `llvm`.
- `moon test`: package or module test validation.
- `moon build --target <target>`: backend-specific build validation.
- `moon info`: generated public interface inspection.
- `moon ide doc '<query>'`: verify available APIs before changing imports or
  calls.
