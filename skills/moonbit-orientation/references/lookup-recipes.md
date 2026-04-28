# Lookup Recipes

Use these recipes when a question needs facts that can drift with toolchain,
dependencies, package configuration, or backend.

## Standard library or dependency API

Default to the installed toolchain first.

1. If inside a MoonBit project, run `moon ide doc ''` to see available packages
   or current package symbols.
2. Search by likely concept with wildcards, for example:
   - `moon ide doc '*json*'`
   - `moon ide doc '*parse*'`
   - `moon ide doc 'String::*find*'`
   - `moon ide doc 'Array::*map*'`
3. If a package is found, inspect it with `moon ide doc '@pkg'`.
4. If a type is found, inspect methods with `moon ide doc 'Type'` or
   `moon ide doc '@pkg.Type::member'`.
5. If `moon ide doc` is unavailable or the package is not installed, use:
   - Standard library: <https://mooncakes.io/docs/moonbitlang/core/>
   - Package registry: <https://mooncakes.io/>

Answer with the verified API only if you can also state how it was verified.
If no API is verified, say what should be checked and give the most likely next
query rather than inventing a name.

If a query returns no results, treat that as "not found in this context", not
as proof that the API does not exist anywhere. Check whether the package is
installed, whether dependencies are fetched, and whether mooncakes or official
docs have newer information.

Stop after the first successful query that answers the user's exact need. For a
capability-plus-import question, a package query such as `moon ide doc '*json*'`
or `moon ide doc '@pkg'` is usually enough. Only inspect individual functions,
types, examples, or call sites when the user asks for signatures, usage, or code
review.

## Ecosystem package availability

Use this when the user asks whether MoonBit has a package, binding, framework,
or integration for another ecosystem concept.

1. Name any stable built-in capability only if it is covered by official docs or
   the installed toolchain.
2. Search the current registry or package docs, usually <https://mooncakes.io/>.
3. If there is a plausible candidate, verify it in a project with
   `moon update`, `moon add <candidate>`, `moon tree`, and
   `moon ide doc '<keyword>'` or `moon ide doc '@pkg'`.
4. If no candidate is confirmed, say that package availability may have changed
   and give the registry keywords to check. Do not invent `moonbitlang/<name>`
   or `@<name>` imports from the concept name.
5. If the practical answer is interop, route to FFI or target-specific docs
   instead of pretending a native package exists.

Budget this lookup tightly. Use one local query such as
`moon ide doc '*keyword*'`, then one registry/docs lookup. If neither confirms a
package, answer with "not confirmed from the checked sources" and the exact
next command or URL. Do not keep trying many search spellings unless the user
explicitly asks for a package hunt.

Useful links:

- Package registry: <https://mooncakes.io/>
- Package workflow:
  <https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html>
- FFI: <https://docs.moonbitlang.com/en/latest/language/ffi.html>

## "Does MoonBit have X?"

1. Answer the capability directly from `capabilities-faq.md` if it is listed
   there.
2. Give the MoonBit model or equivalent concept.
3. If the question depends on exact APIs, run the API recipe above.
4. Include a concrete verification command or link.
5. If you name an exact import, function, or target rule, include the verification
   command or URL in the final answer.

Common examples:

- Inheritance: no class inheritance as the main model; use data types, methods,
  traits, composition, and pattern matching.
- Exceptions: typed error effects with `raise`, `try`, `catch`, and `noraise`,
  not unchecked exceptions.
- Null: do not assume nullable references; model absence explicitly.
- JSON or package APIs: first try `moon ide doc '*json*'`, then mooncakes.
- Async: exists but is experimental; verify against
  <https://docs.moonbitlang.com/en/latest/language/async-experimental.html>.

## Compiler error code

1. Preserve the exact command, working directory, target, file, and diagnostic.
2. Run or suggest `moon check --explain` when available.
3. For `E####`, use:
   `https://docs.moonbitlang.com/en/latest/language/error_codes/E####.html`
4. Fix the first root-cause diagnostic before cascaded diagnostics.
5. Validate with the smallest reproducing command, usually `moon check`,
   `moon test`, or `moon build --target <target>`.
6. If you state the code's meaning, cite the exact error URL or command result.

## Backend or target behavior

1. Inspect `moon.mod.json` for `preferred-target` and `supported-targets`.
2. Inspect `moon.pkg.json` for package-level targets, imports, and backend
   conditions.
3. Treat stable targets as `wasm`, `wasm-gc`, `js`, and `native`.
4. Treat `llvm` as nightly-only; do not recommend it unless the user is
   explicitly on nightly.
5. Use:
   - Package targets:
     <https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html>
   - Module targets:
     <https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html>
   - WebAssembly:
     <https://docs.moonbitlang.com/en/latest/toolchain/wasm/index.html>
   - FFI: <https://docs.moonbitlang.com/en/latest/language/ffi.html>
6. In the final answer, cite one of these public URLs or a local config file
   path. Do not cite this skill's reference files as evidence.

## Project layout or package configuration

1. Find `moon.mod.json` to identify the module root.
2. Find relevant `moon.pkg.json` files for package imports and targets.
3. Use `moon ide outline <file-or-directory>` to inspect structure before broad
   edits.
4. Use `moon ide peek-def <symbol>` before changing calls to unfamiliar local
   APIs.
5. Use `moon ide find-references <symbol>` before renaming or changing public
   behavior.
