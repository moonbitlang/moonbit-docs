---
name: moonbit-docs-maintainer
description: Use when maintaining the moonbitlang/moonbit-docs repository, including Sphinx docs under next/, MoonBit examples under next/sources/, error-code documentation, gettext translations, or the moonbit-tour web app. This skill routes to focused references and validation commands for repo maintenance work.
---

# MoonBit Docs Maintainer

Use this skill for changes to the `moonbitlang/moonbit-docs` repository. It is a
repo-maintenance router, not a MoonBit language tutorial.

## First steps

1. Read the user request and classify the touched area before editing.
2. Inspect the relevant local files. Prefer existing layout and wording patterns.
3. Load only the reference file for the task area.
4. Make minimal, reviewable changes.
5. Run the narrowest validation command that proves the change.

## Routing

- Sphinx docs in `next/`, Markdown pages, images, Sphinx config, or local docs
  builds: read `references/sphinx.md`.
- MoonBit examples under `next/sources/`, excluding `next/sources/error_codes/`:
  read `references/examples.md`.
- Error-code docs under `next/language/error_codes/` or paired examples under
  `next/sources/error_codes/`: read `references/error-docs.md`.
- Translation catalogs under `next/locales/` or gettext template updates: read
  `references/translation.md`.
- Interactive tour changes under `moonbit-tour/`: read `references/tour.md`.
- Typo, spelling, or prose lint changes involving `typos` or `autocorrect`:
  read `references/typo.md`.

If a task spans multiple areas, read the most specific reference first, then any
secondary reference needed for validation.

## Repository Map

- `next/`: Sphinx documentation site. Markdown sources live under `next/`.
  MoonBit example projects used by docs live under `next/sources/`.
- `next/locales/<locale>/LC_MESSAGES/`: gettext translation catalogs.
- `moonbit-tour/`: pnpm-based interactive language tour web app.
- `legacy/`: legacy docs and examples. Treat as reference unless the user asks
  to maintain it directly.
- `scripts/`: repo-level checks for examples and i18n helpers.
- `justfile`: preferred maintainer command entrypoints.

## Tooling Commands

Prefer `just` recipes and `uv`-managed Python dependencies when available. Do
not create ad-hoc virtualenvs unless the task explicitly requires one or `uv` is
unavailable.

- `just i18n`: runs gettext extraction and catalog sync for `zh_CN`.
- `just i18n ja`: runs the i18n flow for another locale.
- `just docs-html`: builds the default Sphinx docs.
- `just docs-html-zh`: builds the Chinese Sphinx docs.
- `just check-docs`: checks non-error-code MoonBit examples under
  `next/sources/`.
- `just check-errors`: checks all error-code docs examples under
  `next/sources/error_codes/`.
- `just check-error 0001`: checks one four-digit error code.

If `just` is unavailable, use the task-specific fallback in the relevant
reference. Example checks fall back to Python scripts; Sphinx and i18n tasks
fall back to manual `cd next` commands.

## General Rules

- Do not edit generated output such as `next/_build/`, `moonbit-tour/dist/`, or
  dependency directories.
- Keep examples runnable. When documentation references code in `next/sources/`,
  update docs and examples together.
- Avoid broad `moon fmt` runs in `next/sources/`; format only touched files when
  formatting is necessary.
- Preserve existing bilingual structure where it exists.
- Prefer functional style for new MoonBit code, and keep changes small.
- Use conventional commit messages if asked to commit; this is a repo-wide rule
  from `AGENTS.md`.

## Validation

Choose the smallest useful check:

- Sphinx docs: `just docs-html`
- Chinese Sphinx build: `just docs-html-zh`
- MoonBit docs examples: `python3 scripts/check-document.py`
- Error-code examples: `python3 next/check_error_docs.py all`
- One error code: `python3 next/check_error_docs.py 0001`
- Tour build: `cd moonbit-tour && pnpm build`
- Prose lint: `autocorrect . --lint --no-diff-bg-color`

If dependencies are missing or a full check is too expensive, run the closest
targeted command and report the remaining risk.
