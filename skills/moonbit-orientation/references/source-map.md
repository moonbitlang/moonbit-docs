# Source Map

Use this file as a URL catalog after choosing a lookup path. For step-by-step
commands, use `lookup-recipes.md`.

## Official documentation

Use official docs for stable language and toolchain concepts:

- Docs home: <https://docs.moonbitlang.com/en/latest/>
- Tutorials: <https://docs.moonbitlang.com/en/latest/tutorial/index.html>
- Beginner tour page:
  <https://docs.moonbitlang.com/en/latest/tutorial/tour.html>
- Native CLI Quickstart:
  <https://docs.moonbitlang.com/en/latest/tutorial/cli-quickstart.html>
- Language docs: syntax, methods, traits, packages, tests, docs, attributes,
  derive, error handling, FFI, async, benchmarks, verification, and error codes.
  Start at <https://docs.moonbitlang.com/en/latest/language/index.html>.
- Toolchain docs: `moon`, packages, workspaces, script mode, coverage, VSCode,
  `moon ide`, and WebAssembly workflows. Start at
  <https://docs.moonbitlang.com/en/latest/toolchain/index.html>.

High-use direct links:

- Method and Trait:
  <https://docs.moonbitlang.com/en/latest/language/methods.html>
- Regex literals:
  <https://docs.moonbitlang.com/en/latest/language/fundamentals.html#regex-literal-expression>
- Regex match expression:
  <https://docs.moonbitlang.com/en/latest/language/fundamentals.html#regex-match-expression>
- Error handling:
  <https://docs.moonbitlang.com/en/latest/language/error-handling.html>
- Managing Projects with Packages:
  <https://docs.moonbitlang.com/en/latest/language/packages.html>
- Writing Tests:
  <https://docs.moonbitlang.com/en/latest/language/tests.html>
- FFI: <https://docs.moonbitlang.com/en/latest/language/ffi.html>
- Async:
  <https://docs.moonbitlang.com/en/latest/language/async-experimental.html>
- Verification:
  <https://docs.moonbitlang.com/en/latest/language/verification.html>
- `moon` command reference:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html>
- Module configuration:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html>
- Package configuration:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html>
- Workspace guide:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html>
- `moon ide` docs:
  <https://docs.moonbitlang.com/en/latest/toolchain/moonide/index.html>
- WebAssembly docs:
  <https://docs.moonbitlang.com/en/latest/toolchain/wasm/index.html>

## API documentation

Use the current local toolchain before guessing exact standard-library and
package APIs.

- Prefer `moon ide doc` when a MoonBit project or installed toolchain is
  available. It queries the compiler/toolchain view of available packages and
  symbols, so it is usually the best first check for "what API exists here?"
- Use `moon ide doc ''` to list packages or symbols in context.
- Use `moon ide doc '@pkg'` to inspect a package, for example `@json` or
  `@buffer` when available.
- Use wildcard queries such as `moon ide doc '*parse*'` or
  `moon ide doc 'String::*rev*'` to discover likely names.
- Use exact symbol queries such as `moon ide doc '@pkg.Type::member'` when the
  package and type are known.
- Use mooncakes.io or package-generated docs when `moon ide doc` is unavailable,
  when checking packages that are not installed locally, or when the user needs
  a linkable external reference.
- Standard library docs: <https://mooncakes.io/docs/moonbitlang/core/>
- Package registry and package docs: <https://mooncakes.io/>
- Package management workflow:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html>
- Verify exact module names, function names, signatures, trait methods,
  constructors, and package-specific behavior.
- Do not infer exact names from another language's standard library.
- For ecosystem packages or bindings, package availability may change after the
  model's training data. Use the registry, package docs, or `moon add` in a
  real project before saying a package exists or naming an import.
- If local dependencies are present, inspect dependency declarations and
  generated interfaces as well.

## Tour

Use the MoonBit Tour (<https://tour.moonbitlang.com/>) for beginner
explanations and quick interactive examples. It is a good first source for
learning syntax and core ideas, but not the final source for package-specific
APIs.

## Examples

Use examples when the user needs runnable structure, not just a definition.

- Check whether the example is a full module, package, single file, or docs
  snippet.
- Online examples index:
  <https://docs.moonbitlang.com/en/latest/example/index.html>.
- Source examples, when needed:
  <https://github.com/moonbitlang/moonbit-docs/tree/main/next/sources>.
- Prefer examples that match the user's target backend and package shape.

## Error-code docs

Use error-code docs for diagnostics with `E####`.

- Error-code index:
  <https://docs.moonbitlang.com/en/latest/language/error_codes/index.html>.
- Specific error URL pattern:
  `https://docs.moonbitlang.com/en/latest/language/error_codes/E####.html`.
- They are best for explaining the cause and a repair pattern.
- They may not all have complete paired runnable projects.
- If examples are missing, rely on the diagnostic, local code, and narrow
  validation.

## Local project files

Use local files for anything project-specific:

- imports and visibility
- dependency versions and package names
- target configuration
- local style and helper conventions
- tests and expected outputs

Local truth beats generic guidance when they conflict.

## Installed toolchain truth

Use installed commands for facts that can drift faster than docs:

- `moon ide doc` for currently available APIs and docs.
- `moon ide peek-def` for definitions.
- `moon ide find-references` for usages.
- `moon ide outline` for package or file structure.
- `moon version` when behavior may differ by toolchain version.
