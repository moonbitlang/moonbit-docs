# Answer Shapes

Use this file first for "Does MoonBit have X?", API availability, and quick
capability questions. Load larger references only if this file does not cover
the needed concept.

## Capability Question Shape

Answer in this order:

1. **Short answer**: yes, no, or yes-with-caveat.
2. **MoonBit equivalent**: the MoonBit model or idiom the user should use.
3. **When to verify**: say whether exact APIs, imports, signatures, target
   behavior, or package names need local verification.
4. **Command or link**: give one concrete command or public URL.

Do not end with a vague "check the docs." If exact names were not verified, say
that plainly and give the lookup command.

Never cite this skill's files as the user's final source. Final evidence must be
a command the agent ran or recommends, a public URL, or a local project file
that belongs to the user's codebase.

## API Availability Shape

For standard-library or package API questions:

1. Give the capability-level answer if stable.
2. Say when model memory may be stale because the feature, package, or API is
   new, experimental, third-party, or target-specific.
3. Prefer `moon ide doc` in the user's project for exact APIs.
4. For package availability, check mooncakes or a real `moon add <candidate>`
   result before saying a package exists.
5. If a local project is unavailable, use <https://mooncakes.io/docs/moonbitlang/core/>
   or <https://mooncakes.io/>.
6. Do not name exact imports, function signatures, or method behavior unless
   verified by command output, local files, or public API docs.

Spend at most one local API query and one registry/docs lookup before answering
at capability level. Repeated searches with the same keyword in different forms
usually waste context; say what was not confirmed and give the next check.

Useful first commands:

- `moon ide doc '*json*'` for JSON-like APIs.
- `moon ide doc ''` for available packages or current package symbols.
- `moon ide doc 'String::*find*'` for string methods.
- `moon ide doc 'Array::*map*'` for array methods.

Stop after the first successful source that answers the user's requested level
of detail. Do not inspect functions, examples, or call sites unless the user
asked for signatures, usage, code review, or validation.

## Common Stable Answers

- **Inheritance**: MoonBit does not use class inheritance as the primary model.
  Use structs/enums, methods, traits, composition, and pattern matching. Source:
  <https://docs.moonbitlang.com/en/latest/language/methods.html>.
- **Traits/interfaces**: MoonBit has traits for ad-hoc polymorphism and
  overloading. Do not import Rust lifetime/ownership assumptions or Go
  structural-interface assumptions. Source:
  <https://docs.moonbitlang.com/en/latest/language/methods.html>.
- **Exceptions**: MoonBit has typed error effects with `raise`, `try`, `catch`,
  and `noraise`, not unchecked JavaScript-style exceptions. Source:
  <https://docs.moonbitlang.com/en/latest/language/error-handling.html>.
- **Null**: Do not model ordinary MoonBit code around implicit nullable
  references. Use explicit absence in the type model, then verify exact
  option-like APIs with `moon ide doc`.
- **JSON support**: answer at capability level, then verify exact package/API
  names with `moon ide doc '*json*'` or mooncakes. If you name an import or
  function, state the command or URL that verified it.
- **LLVM**: `llvm` is nightly-only. Stable/common targets are `wasm`,
  `wasm-gc`, `js`, and `native`; `--target all` excludes `llvm`. Do not invent
  target configuration syntax for combining stable targets with `llvm`; point
  to the target configuration docs:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html> and
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html>.
- **New syntax**: verify against official docs or local examples before
  answering from memory. New syntax is high-risk for stale model knowledge.
- **Experimental or ecosystem features**: give the current capability only at
  the level you can support. For exact packages, versions, imports, APIs, or
  backend support, say model knowledge may be stale and verify with installed
  `moon` commands, official docs, mooncakes, or local dependency files.

## Unknown Ecosystem Package Shape

Use this for questions such as "is there a MoonBit package for Lottie?" or
"what should I import for <ecosystem library>?"

1. **Short answer**: say whether it is a known built-in capability, a verified
   package, not found from checked sources, or unknown because it was not
   checked.
2. **MoonBit equivalent**: use the closest stable route, such as stdlib API,
   mooncakes package, FFI/interop, or implementing a small wrapper.
3. **Freshness note**: say package availability can change and exact dependency
   names must come from current registry or project files.
4. **Command or link**: give one concrete verification path, such as
   `moon update` plus `moon add <candidate>`, `moon ide doc '*keyword*'`, or
   <https://mooncakes.io/>.

Do not say "there is no package" unless a current registry or public search was
actually checked. Prefer "I cannot confirm a package from the available
sources; verify on mooncakes before choosing an import" when the check is
incomplete.

For absence claims, avoid exhaustive searching. One relevant local search and
one registry/docs search are enough to justify "not confirmed from the checked
sources"; the user can perform the live registry check if the environment cannot.

## If More Detail Is Needed

- Language capability comparisons: load `capabilities-faq.md`.
- Exact API lookup procedure: load `lookup-recipes.md`.
- Coming from another language: load `mental-models.md`.
- Toolchain, package, workspace, or backend setup: load `toolchain-map.md`.
