# Toolchain Map

Use local project files as source of truth before changing commands or config.

## Project files

- `moon.mod.json`: module-level metadata and dependencies.
- `moon.pkg.json`: package-level imports, targets, build settings, and test
  related settings.
- Workspace configuration may affect multiple packages or modules. Inspect the
  repository layout before assuming a single-package project.

## Common `moon` commands

- `moon new <path>`: create a new module.
- `moon check`: typecheck and validate quickly without building object files.
- `moon build`: build the current package or module.
- `moon run <package-or-file>`: run a main package or file.
- `moon test`: run tests.
- `moon fmt`: format source; use intentionally scoped formatting in existing
  projects.
- `moon doc`: generate documentation.
- `moon info`: generate public interface files for packages.
- `moon bench`: run benchmarks.
- `moon coverage`: coverage utilities.
- `moon add`, `moon remove`, `moon install`, `moon update`, `moon tree`:
  dependency and registry workflows.
- `moon ide doc '<query>'`: discover available packages, symbols, methods, and
  documentation from the installed toolchain.
- `moon ide peek-def <symbol>`: find definitions with compiler-aware context.
- `moon ide find-references <symbol>`: find usages across the project.
- `moon ide outline <file-or-directory>`: inspect structure before editing.

## API discovery with `moon ide`

Use `moon ide` when the question is "what symbols/packages exist?" or "where is
this defined?" Text search is still useful, but `moon ide` has compiler context.

- `moon ide doc ''`: list available packages or symbols for the current context.
- `moon ide doc '@pkg'`: list exported symbols in a package.
- `moon ide doc 'String'`: inspect a type and its methods.
- `moon ide doc 'String::*find*'`: wildcard-search methods on a type.
- `moon ide doc '*parse*'`: wildcard-search symbol names.
- `moon ide peek-def Type::method`: inspect a definition before changing calls.

If the docs for `moon ide` appear stale, rely on the installed command's output
and `moon version` for the current environment. The docs entrypoint is
<https://docs.moonbitlang.com/en/latest/toolchain/moonide/index.html>.

## Targets

- Common stable targets include `wasm`, `wasm-gc`, `js`, `native`, and `all`.
- `llvm` is nightly-only. Do not recommend it for stable users.
- `--target all` means `wasm`, `wasm-gc`, `js`, and `native`; it excludes
  `llvm`.
- Ask or inspect which target matters before debugging backend behavior.
- Use `moon check --target all` only when broad target coverage is valuable and
  the project supports it.
- For target configuration, use the package configuration docs:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html>.
- If explaining targets to a user, cite the package or module configuration URL
  above. Do not cite this skill file as the source.
- Do not invent configuration syntax for combining stable targets with
  nightly-only `llvm`. State that `llvm` must be handled explicitly on nightly,
  then point to package/module target configuration docs for exact syntax:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html> and
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html>.

## Tests and docs

- Prefer `moon test` for behavior checks.
- Prefer `moon check` when only typechecking is needed.
- Use `moon doc` when documentation generation is the deliverable.
- Use `moon coverage` when the user's goal is test coverage, not just passing
  tests.

## Single-file and examples

- `moon check <file>` can be useful for single `.mbt` or `.mbt.md` checks when
  supported by the toolchain.
- For examples copied from docs, confirm whether the code is meant to be a
  standalone project, a package example, or a documentation snippet.

## When not to change tooling

- Do not add dependencies to fix a missing import until the desired package is
  confirmed.
- Do not broaden targets to `all` unless cross-target behavior is relevant.
- Do not run broad formatting across an existing repository unless requested.
