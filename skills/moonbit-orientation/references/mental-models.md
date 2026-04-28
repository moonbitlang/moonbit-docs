# Mental Models

Use this file when the user brings assumptions from another language. Keep the
comparison short, then show the MoonBit way.

## From Go

- Think modules and packages, but inspect `moon.mod.json` and `moon.pkg.json`
  instead of assuming Go module layout.
- Prefer explicit data types plus functions, methods, and traits over interface
  substitution patterns copied from Go.
- Error handling is typed with `raise`/`try`/`catch`, not `if err != nil`.
- Use `moon check` for fast feedback before deeper builds.

## From Rust

- Traits exist, but do not assume Rust's ownership, borrowing, lifetimes, or
  orphan-rule details apply.
- Pattern matching and algebraic data types are natural tools.
- When you want `Result`-style APIs, first check whether the codebase expects
  MoonBit typed errors with `raise` or explicit result-like values.
- Verify exact stdlib names instead of translating Rust method names directly.

## From TypeScript or JavaScript

- Do not model everything with dictionaries, nullable objects, or dynamic
  shapes. Prefer explicit MoonBit types.
- Backend `js` exists, but MoonBit source is statically typed and compiled.
- For interop, confirm whether the target is `js`, `wasm`, `wasm-gc`, or
  `native`.
- For backend and FFI details, use the FFI docs
  (<https://docs.moonbitlang.com/en/latest/language/ffi.html>) and WebAssembly
  docs (<https://docs.moonbitlang.com/en/latest/toolchain/wasm/index.html>).
- Avoid inventing npm-like workflows; MoonBit project behavior lives in `moon`
  config and commands.

## From OCaml or ML-family languages

- Algebraic data types and pattern matching are a useful starting point.
- MoonBit has its own package, method, trait, and toolchain model; do not assume
  OCaml module semantics.
- Check MoonBit syntax for labelled arguments, optional arguments, methods, and
  error effects rather than translating directly.

## From object-oriented languages

- Do not look for class inheritance first.
- Model the domain with structs/enums, attach behavior with methods, and abstract
  shared operations with traits.
- Use composition and pattern matching where subclass hierarchies would be used
  elsewhere.

## From C/C++ or systems languages

- Confirm the backend and interop boundary early.
- Do not assume pointer-level control unless the docs for the selected backend
  and FFI path provide it:
  <https://docs.moonbitlang.com/en/latest/language/ffi.html>.
- Prefer MoonBit data modeling and standard library abstractions until lower
  level interop is required.
