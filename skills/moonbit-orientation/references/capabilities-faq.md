# Capabilities FAQ

Use this file for capability-level answers. If the user asks for exact module
names, function names, signatures, or package behavior, verify with `moon ide
doc`, official API docs, or the local project.

## Answering rule

For capability questions, do not merely say "check the docs." Give the stable
capability answer first, then the MoonBit model, then the exact command or link
to verify details. If you name an exact API, import, function, or error meaning,
also name the command or URL used to verify it.

## Language model

- MoonBit has algebraic data types, pattern matching, structs, enums, methods,
  traits, generics, labelled arguments, optional arguments, and derive support.
- MoonBit does not use class inheritance as its main abstraction model. Explain
  code in terms of data types, methods, traits, composition, and pattern
  matching.
- MoonBit methods are associated with types. Method definitions normally belong
  with the type's package; private local methods can extend foreign types in
  limited cases.
- MoonBit traits are for ad-hoc polymorphism and overloading. They are closer to
  typeclass-style constraints than to subclass inheritance.
- MoonBit supports operator overloading through built-in traits and selected
  method aliases.

Common direct answers:

- **Does MoonBit have inheritance?** Not class inheritance as the primary model.
  Use structs/enums for data, methods for attached behavior, traits for shared
  operations, and composition or pattern matching for variation. Source:
  <https://docs.moonbitlang.com/en/latest/language/methods.html>.
- **Does MoonBit have traits/interfaces?** It has traits for ad-hoc
  polymorphism and overloading. Do not assume Rust lifetime rules or Go
  structural interfaces. Source:
  <https://docs.moonbitlang.com/en/latest/language/methods.html>.
- **Does MoonBit have generics?** Yes. Verify exact syntax in the language docs
  if writing examples:
  <https://docs.moonbitlang.com/en/latest/language/fundamentals.html>.
- **Does MoonBit have pattern matching?** Yes, and it is a normal way to work
  with enums and structured data. Start at
  <https://docs.moonbitlang.com/en/latest/language/fundamentals.html>.

## Error handling

- MoonBit has typed error handling with `raise`, `try`, `catch`, and `noraise`.
- Use `raise?` for error-polymorphic higher-order functions.
- `fail` is the usual convenience for unrecoverable failures with source
  location context.
- Do not describe MoonBit errors as JavaScript-like unchecked exceptions; the
  effect is represented in function signatures.

Common direct answers:

- **Does MoonBit have exceptions?** It has typed error effects, not unchecked
  exceptions. Explain `raise`, `try`, `catch`, and `noraise`. Source:
  <https://docs.moonbitlang.com/en/latest/language/error-handling.html>.
- **Does MoonBit have Result?** Do not assume the exact stdlib API name. First
  decide whether local code uses typed errors or explicit result-like values,
  then verify APIs with `moon ide doc '*result*'`.

## Nullability and optional data

- Do not assume nullable references by default.
- Model absence with the appropriate option-like type or domain-specific enum.
- Check `moon ide doc` or the standard library docs
  (<https://mooncakes.io/docs/moonbitlang/core/>) for exact option/result APIs
  before naming functions.

Common direct answers:

- **Does MoonBit have null?** Do not model normal MoonBit code around implicit
  nullable references. Use explicit absence in the type model and verify the
  exact option-like API with `moon ide doc '*option*'`.

## Tooling

- MoonBit has a `moon` build system with commands for creating modules, checking,
  building, running, testing, formatting, docs, dependencies, benchmarks, and
  coverage.
- MoonBit has modules, packages, and workspaces. Use local `moon.mod.json` and
  `moon.pkg.json` files as the source of truth for a project.
- MoonBit has IDE support, including VSCode support and `moon ide`.
- MoonBit has package registry and API documentation at <https://mooncakes.io/>.

Common direct answers:

- **How do I find an API?** Prefer `moon ide doc` in the user's project, then
  mooncakes if local lookup is unavailable.
- **How do I inspect local code?** Prefer `moon ide outline`, `moon ide
  peek-def`, and `moon ide find-references` over plain text search when symbol
  precision matters.
- **How do I validate code?** Use `moon check` for compile/type feedback and
  `moon test` for behavior.

## Backends and interop

- MoonBit's stable/common targets are `wasm`, `wasm-gc`, `js`, and `native`.
- `llvm` is only for nightly toolchains. Do not present it as a normal stable
  target, and do not recommend it unless the user is explicitly using nightly.
- `--target all` expands to `wasm`, `wasm-gc`, `js`, and `native`; it does not
  include `llvm`.
- Backend behavior can matter. Confirm the selected `--target` before debugging
  target-specific output.
- MoonBit supports FFI and WebAssembly workflows, but exact boundary code is
  backend-specific and should be verified against the FFI docs
  (<https://docs.moonbitlang.com/en/latest/language/ffi.html>) or WebAssembly
  toolchain docs (<https://docs.moonbitlang.com/en/latest/toolchain/wasm/index.html>).

Common direct answers:

- **Does MoonBit support LLVM?** Only with nightly toolchains. Do not recommend
  it for stable users.
- **Does `--target all` include LLVM?** No. It covers `wasm`, `wasm-gc`, `js`,
  and `native`.
- **Can one module mix backends?** MoonBit supports target configuration such as
  `preferred-target`, `supported-targets`, and package-level target settings.
  Verify the project config and target docs.

## Standard library and packages

- This skill does not bundle the full standard library.
- For "is there a JSON/string/array/map/etc. API?", answer at capability level
  first, then verify exact names with the installed toolchain.
- Prefer `moon ide doc` for the current local project and current installed
  MoonBit toolchain. Its documentation page may lag the CLI, so prefer command
  output over memory when available.
- Useful `moon ide doc` queries:
  - `moon ide doc ''`: list available packages or current package symbols.
  - `moon ide doc '@json'`: inspect an available package.
  - `moon ide doc '*parse*'`: search symbols by wildcard.
  - `moon ide doc 'String::*rev*'`: search methods on a type.
  - `moon ide doc '@pkg.Type::member'`: inspect a specific member.
- Use mooncakes.io and package docs when `moon ide doc` is unavailable, when the
  package is not installed locally, or when the user needs a browsable external
  source:
  - Standard library: <https://mooncakes.io/docs/moonbitlang/core/>
  - Package registry: <https://mooncakes.io/>
- For third-party packages, inspect local dependency declarations before
  suggesting an import or exact package name.

Common direct answers:

- **Does MoonBit have JSON support?** Do not answer with an unverified module
  name. In a project, run `moon ide doc '*json*'`; otherwise check
  <https://mooncakes.io/>. If you provide an import such as `@json`, state
  exactly where it was verified.
- **Does MoonBit have string/array/map APIs?** Yes at the capability level, but
  verify exact methods with queries like `moon ide doc 'String::*find*'` or
  `moon ide doc 'Array::*map*'`.
- **How do I know what packages are available?** Run `moon ide doc ''` in the
  project or search <https://mooncakes.io/>.

## Experimental or moving areas

- Async exists but should be treated as experimental unless current docs say
  otherwise. Check <https://docs.moonbitlang.com/en/latest/language/async-experimental.html>.
- Verification and some advanced tooling are specialized. Prefer official docs
  (<https://docs.moonbitlang.com/en/latest/language/verification.html>) and
  local validation over memory.

## New syntax features

- Treat new MoonBit syntax as high-risk for stale model memory. Verify against
  official docs or local examples before answering.
- For regex, new code should prefer regex match expression `=~`; `lexmatch` and
  `lexmatch?` are deprecated. Sources:
  - <https://docs.moonbitlang.com/en/latest/language/fundamentals.html#regex-match-expression>
  - <https://docs.moonbitlang.com/en/latest/language/fundamentals.html#lexmatch>
- Regex literals use `re"..."`. Named regex capture groups such as
  `(?<id>...)` are capture metadata, not MoonBit binders; use `as` in `=~` to
  bind matched text.
- In `=~`, use `before` and `after` to bind unmatched prefix/suffix as
  `StringView`.
- `\b` and `\B` work when a regex literal is used as a first-class `Regex`
  value, but are not currently available in `=~` constant contexts.
- To match a literal `{`, use `[{]` rather than `\{`.
