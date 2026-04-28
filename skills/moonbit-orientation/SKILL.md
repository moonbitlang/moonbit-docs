---
name: moonbit-orientation
description: Use this skill when the user needs help solving MoonBit language, code, compiler diagnostic, package, toolchain, backend, FFI, test, or "does MoonBit have X?" questions. Use it even when MoonBit is only implied by .mbt files, moon.mod.json, moon.pkg.json, moon commands, wasm/js/native targets, or mooncakes packages. This skill helps choose the right MoonBit source of truth, discover APIs with moon ide, avoid stale assumptions, and validate fixes.
---

# MoonBit Orientation

Use this skill to solve MoonBit developer questions by identifying the missing
context first. This is an orientation skill, not a bundled copy of all MoonBit
documentation.

## Default workflow

1. Classify the user's situation and likely missing layer.
2. Check the gotchas below and the freshness gate before choosing a path.
3. Load the smallest relevant reference file.
4. If code, APIs, package config, or diagnostics are involved, inspect local
   files or run the narrowest discovery command before answering.
5. Give a practical answer: direct capability answer, MoonBit equivalent,
   exact verification command or link, and narrow validation command when code
   changed.
6. If the final answer gives an exact API, import, error-code meaning, target
   rule, or docs claim, include the command or URL that verifies it. Do this
   even when the answer is short.

If the user asks for exact standard-library APIs, package APIs, or recently
changed behavior, verify with `moon ide doc`, official API docs, package docs,
or local project files instead of guessing.

## Freshness gate

Some MoonBit facts move faster than model memory: new syntax, experimental
features, package availability, package APIs, dependency versions, target
support, and command flags. For these, do not turn memory into a final answer.

Use this pattern:

1. Say the capability-level answer if it is stable.
2. State that exact APIs, package names, or tool behavior may have changed.
3. Choose the current source: local project files, installed `moon` commands,
   official docs, mooncakes package docs, or the registry.
4. If the source cannot be checked in the current environment, say so and give
   the next check. Do not present an unchecked package, import, function, flag,
   or version as fact.

This is not a rule to verify every stable fact. It is a rule to admit when
MoonBit ecosystem or feature knowledge may be stale, then check the latest
source before making exact claims.

Keep freshness checks bounded. For package or API discovery, use one local
toolchain query and, if needed, one registry or public-docs lookup. If those do
not confirm the exact fact, stop and answer "not confirmed from the checked
sources" with the next verification command. Do not run many near-duplicate web
searches just to prove absence.

Keep discovery narrow. Once a source-of-truth command or document answers the
user's requested level of detail, stop searching unless the user asked for
examples, signatures, alternatives, or validation by execution. Do not spend
extra context proving nearby facts that are not needed for the answer.

When recommending external material, provide a concrete URL from
`references/source-map.md`. Do not assume the user has this repository checked
out.

## Gotchas

- For standard-library and dependency APIs, default to `moon ide doc` in the
  user's project. It reflects the installed toolchain and dependencies better
  than memory or stale docs.
- For ecosystem package availability, do not infer existence from a familiar
  technology name. Check mooncakes or `moon add <candidate>` in a disposable or
  user project before naming a dependency as available.
- `llvm` is nightly-only. Stable backend guidance should use `wasm`, `wasm-gc`,
  `js`, or `native`; `--target all` excludes `llvm`.
- Do not answer exact API names by translating from Rust, Go, JavaScript, or
  OCaml names. Discover the MoonBit API first.
- Do not send users to "the docs" without a concrete URL or command.
- Local `moon.mod.json` and `moon.pkg.json` beat generic advice for package
  names, imports, targets, and dependencies.
- For `E####` diagnostics, use `moon check --explain` or the exact online error
  page pattern before inventing a cause.

## Verification contract

Treat MoonBit facts as three tiers:

- **Stable capability facts**: language/toolchain shape covered by this skill,
  such as no class-inheritance-first model, typed errors, common stable targets,
  and `llvm` being nightly-only.
- **Verified exact facts**: exact API names, signatures, package names, imports,
  target config, and local project conventions confirmed by `moon ide`, local
  files, generated interfaces, official docs, or mooncakes.
- **Unverified guesses**: plausible API names or behavior inferred from another
  language, memory, or naming convention.

Never present unverified guesses as facts. If an exact fact is not verified,
say what must be checked and provide the command or URL. Prefer "I can answer
the capability, but the exact API needs `moon ide doc '*json*'`" over a
plausible module or function name.

If a verification command fails, returns no result, or was only checked outside
the user's project, do not cite it as if it proved the exact API. Say what the
failure means and give the next source, for example package installation,
`moon tree`, mooncakes package docs, or a local dependency file.

If you did verify an exact fact, say so compactly: "Verified with
`moon ide doc '@json'`" or "Source: <URL>". Do not omit the verification source
after naming exact imports, functions, or error meanings.

Do not cite this skill's own reference files as the final verification source
for users. The final answer should cite an external URL, a local project file,
or a command result. The skill is guidance for the agent, not user-facing
evidence.

This rule still applies when a reference file contained the answer. Use the
reference file to route the work, then cite the public URL, command, or local
project file named by that reference.

Avoid "likely" guesses for exact API behavior. For unknown calls such as
`Json.parse` or `result.unwrap()`, say "verify whether this returns typed errors
or a result-like value" instead of guessing which one it uses.

## Situation routing

- Learning MoonBit or asking where to start: read `references/question-routing.md`
  and `references/source-map.md`.
- Asking "Does MoonBit have X?", API availability, or quick capability
  questions: read `references/answer-shapes.md` first. Load
  `references/capabilities-faq.md` only when the quick shape does not cover the
  concept or the user asks for a broader comparison. If exact APIs are involved,
  use `references/lookup-recipes.md`.
- Coming from Go, Rust, TypeScript, OCaml, or another language: read
  `references/mental-models.md`.
- Writing, reviewing, or refactoring MoonBit code: read `references/idioms.md`.
- Debugging compiler output, `moon` output, package errors, backend errors, or
  diagnostics with an `E####` code: read `references/diagnostics-playbook.md`
  and the relevant recipe in `references/lookup-recipes.md`.
- Setting up modules, packages, workspaces, tests, docs, coverage, or build
  targets: read `references/toolchain-map.md`.
- Choosing between official docs, mooncakes API docs, the Tour, examples, error
  code docs, or local project inspection: read `references/source-map.md`.

For tasks that span multiple areas, read the most specific reference first, then
one secondary reference if needed.

## Missing-layer checklist

Before answering, decide whether the unknown is most likely:

- language semantics
- MoonBit idiom or style
- toolchain behavior
- package, dependency, or standard-library API
- backend limitation or target-specific behavior
- official docs, examples, or error-code reference
- project-local convention

State uncertainty briefly when it matters, but do not stop at uncertainty if a
recipe can resolve it. For concrete code work, prefer a narrow validation
command such as `moon check`, `moon test`, or `moon build` with the relevant
`--target`.

## Boundaries

- Do not pretend this skill contains the full language specification.
- Do not provide exact standard-library signatures unless they were verified.
- Do not use this skill for maintaining the `moonbit-docs` repository itself;
  use the repo maintainer skill for docs, translation, Sphinx, or example
  maintenance workflows.
- Keep answers practical: show the next source to check, the likely fix, and the
  narrow command that would validate it.
