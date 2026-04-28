# Question Routing

Start with the user's task shape, not with a memorized answer.

## Learning or onboarding

Use this route when the user asks how to learn MoonBit, where to start, or how a
concept works.

- If they are brand new, point to the interactive Tour
  (<https://tour.moonbitlang.com/>) or the Native CLI Quickstart
  (<https://docs.moonbitlang.com/en/latest/tutorial/cli-quickstart.html>)
  before deep language pages.
- If they know another language, load `mental-models.md`.
- If they need a project, load `toolchain-map.md`.
- Prefer small runnable examples over broad summaries.

## Writing or reviewing code

Use this route when the user provides MoonBit code or asks for idiomatic code.

- Inspect nearby project files before assuming package names, visibility, or
  dependencies.
- Load `idioms.md` for stable style guidance.
- If unfamiliar symbols or APIs are involved, use `lookup-recipes.md` before
  editing.
- Check whether the issue is semantic, API-specific, or project-local.
- Validate with `moon check` or `moon test` when feasible.

## Debugging diagnostics

Use this route when the user provides compiler output, `moon` output, failing
tests, package errors, or an `E####` code.

- Load `diagnostics-playbook.md`.
- Preserve the exact diagnostic text and location.
- If an error code appears, consult exact error-code docs when available. The
  online index is
  <https://docs.moonbitlang.com/en/latest/language/error_codes/index.html>.
- Fix the first root-cause diagnostic before chasing cascaded errors.

## Project or toolchain setup

Use this route for modules, packages, workspaces, dependencies, tests, docs,
coverage, build targets, and publishing.

- Load `toolchain-map.md`.
- Use `lookup-recipes.md` for backend, package, and project-layout checks.
- Inspect `moon.mod.json`, `moon.pkg.json`, and workspace layout if local files
  exist.
- Distinguish module-level, package-level, and workspace-level configuration.

## Capability questions

Use this route for "Does MoonBit have X?", "Can MoonBit do Y?", or "What is the
MoonBit equivalent of Z?"

- Load `answer-shapes.md` first.
- Answer at capability level first.
- For exact APIs, route to `moon ide doc`, standard-library docs
  (<https://mooncakes.io/docs/moonbitlang/core/>), or the package registry
  (<https://mooncakes.io/>).
- For target-specific behavior, also load `toolchain-map.md` or `source-map.md`.
- Load `capabilities-faq.md` only when the quick answer shape does not cover the
  concept or the user asks for a broader comparison.

## Choosing sources

Use this route when the agent is unsure where truth lives.

- Load `source-map.md`.
- Prefer local project files for project-specific behavior.
- Prefer official docs (<https://docs.moonbitlang.com/en/latest/>) for language
  and toolchain concepts.
- Prefer `moon ide doc` or mooncakes API docs
  (<https://mooncakes.io/docs/moonbitlang/core/>) for exact library modules,
  functions, and signatures.
