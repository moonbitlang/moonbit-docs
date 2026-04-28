# Idioms

Use this file for code generation, review, and refactoring. Keep guidance
practical and verify project-local conventions before changing code.

## General style

- Prefer clear data modeling with structs, enums, and pattern matching.
- Use methods for behavior naturally attached to a type.
- Use traits for shared operations and ad-hoc polymorphism, not as class
  inheritance.
- Prefer small direct code over abstractions that hide only a few lines.
- Preserve the style of the surrounding package.

## Package-aware code

- Check package boundaries before adding public definitions.
- Avoid duplicating a helper if a local package already exposes the concept.
- Do not invent imports or dependency names. Inspect `moon.pkg.json` and API
  docs.
- When adding public APIs, consider whether `moon info` should be run to inspect
  the exposed interface.

## Error handling

- Use MoonBit's typed error model when the surrounding code uses `raise`,
  `try`, `catch`, or `noraise`.
- Do not translate every error into an option-like value unless that is the
  local pattern.
- For unrecoverable failures, prefer the project's existing failure style; the
  standard `fail` helper is common in examples.

## Tests

- Add or update focused tests for behavior changes.
- Use `moon test` for behavior and `moon check` for type-level validation.
- If the package is target-sensitive, validate the relevant target explicitly.

## Formatting

- Use `moon fmt` intentionally and narrowly in existing projects.
- Avoid formatting unrelated files while answering a small question.
- If the user only asked for explanation or review, do not rewrite code.

## API uncertainty

- If a solution depends on a standard-library function name or signature, verify
  it with `moon ide doc`, mooncakes API docs
  (<https://mooncakes.io/docs/moonbitlang/core/>), or local generated
  interfaces.
- It is better to say which API needs checking than to provide a plausible but
  unverified name.

When reviewing code with unknown APIs, separate API verification from style
judgment. For example, for code that calls `Json.parse` and `result.unwrap()`,
do not assume either API exists. First suggest `moon ide doc '*json*'`,
`moon ide doc '@json'`, and `moon ide doc '*result*'`; then review whether the
verified API matches the project's error-handling style.

Do not say an unknown API "likely" returns typed errors, a `Result`, an option,
or any other shape. Phrase it conditionally: "If `Json.parse` raises, use
`try`/`catch`; if it returns a result-like value, verify whether `unwrap` exists
or prefer explicit handling."

## Review posture

- Lead with correctness, diagnostics, target behavior, tests, and project
  conventions.
- Call out when the code looks like it imported assumptions from another
  language.
- Suggest the smallest change that makes the code idiomatic and verifiable.
