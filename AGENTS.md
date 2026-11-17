# AGENTS

## Purpose
This repo hosts MoonBit documentation. It includes the Sphinx-based docs site and
an interactive language tour.

## Layout
- `next/`: Sphinx docs. Sources are Markdown files under `next/` plus examples in
  `next/sources/`. Translation catalogs live in `next/locales/zh_CN/LC_MESSAGES/`.
- `moonbit-tour/`: Interactive tour web app (pnpm-based).
- `legacy/`: Legacy docs/examples.
- `scripts/`: Repo-level checks for MoonBit examples under `next/sources/`.
- `justfile`: Maintainer command entrypoints. Prefer these over hand-written
  multi-step shell flows when available.
- `document.code-workspace`: VSCode tasks and dev shortcuts.

## Sphinx docs (next)
- Prefer `uv` for Python tooling. Do not create ad-hoc virtualenvs unless a
  task explicitly requires one or `uv` is unavailable.
- Dev server: `just docs-watch` (Chinese: `just docs-watch-zh`)
- Build: `just docs-html` (Chinese: `just docs-html-zh`, Japanese:
  `just docs-html-ja`)

## Translation workflow (next)
- Before editing translation catalogs, sync templates first with `just i18n`
  (or `just i18n <locale>`). This wraps `make gettext` and `sphinx-intl update`
  so generated i18n entries stay aligned with source docs.
- Translate missing strings in `next/locales/zh_CN/LC_MESSAGES/*.po`.
- If the source string does not need translation, such as code-only content,
  leave `msgstr` empty.
- Commit catalog changes produced by the i18n sync together with the related
  source or translation change.
- If `#, fuzzy` is present and the translation is verified, remove the flag.
- Do not use `msgfmt` as the default validation command; prefer `just i18n`
  followed by a Sphinx build.

## Checks
- `just check-docs`: runs MoonBit example checks under `next/sources/`.
- `just check-errors`: validates all error-code examples.
- `just check-error 0001`: validates one error-code example.
- When touching examples under `next/sources/`, avoid broad `moon fmt` runs that
  rewrite unrelated files.

## Toolchain and release updates
- Use the published pre-release toolchain as the source of truth for upcoming
  release documentation and runnable examples when it is available. Fall back
  to nightly only when no pre-release is available. Inspect `moon version --all`
  and confirm the published channel before changing language or diagnostic docs.
- Nightly represents ongoing development and may differ from the upcoming
  release. Keep both CI channels as compatibility signals, but do not preserve
  obsolete pre-release documentation solely to make nightly checks pass.
- Keep the default value of `release` in `next/conf.py` as `nightly`. Tagged
  builds derive their displayed release from the build environment.
- Stable documentation is an immutable semantic-version tag on a merged commit.
  Validate the intended commit with the stable toolchain before tagging it, and
  never place a release tag on an unmerged pull-request commit.
- The Chinese website is published from stable release tags, not from the
  default branch. Do not make its release workflow publish nightly content.

## moonbit-tour
- Install/build: `just tour-install && just tour-build && just tour-preview`
- Dev server: `just tour-dev`

## Commit style
- Use conventional commits.
