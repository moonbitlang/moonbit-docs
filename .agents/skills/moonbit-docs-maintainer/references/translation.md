# Translation Workflow

Use this reference for gettext catalogs under `next/locales/` and translation
template synchronization.

## Relevant paths

- `next/locales/zh_CN/LC_MESSAGES/*.po`: Chinese translation catalogs.
- `next/locales/ja/LC_MESSAGES/*.po`: Japanese translation catalogs, when
  present.
- `justfile`: preferred one-command i18n entrypoint.
- `next/_build/gettext/`: generated gettext templates. Do not hand-edit as a
  source of truth.

## Workflow

1. Update source documentation first.
2. Before editing `.po` catalogs, run the i18n sync flow so generated entries
   match the current docs source.
3. Commit catalog changes produced by the sync together with the related source
   or translation change; do not leave required i18n updates behind.
4. Translate missing `msgstr` entries in the relevant `.po` files.
5. If the source string does not need translation, such as code-only content,
   leave `msgstr` empty instead of copying or inventing a translation.
6. If a `#, fuzzy` flag remains, keep it unless the translation has been
   verified. Remove it only after verification.
7. Preserve PO syntax exactly; malformed catalogs break Sphinx builds.

## Commands

Run these commands from the repository root.

- Full Chinese update: `just i18n`
- Locale-specific update: `just i18n ja`
- If `just` is unavailable, use the manual flow:
  - `cd next && make gettext`
  - `cd next && sphinx-intl update -p _build/gettext -l zh_CN`

The `just i18n` recipe is the preferred one-line command and uses `uv` with
`next/requirements.txt`. The manual flow is only a fallback.

## Validation

- Chinese docs build: `just docs-html-zh`
- Default docs build after source changes: `just docs-html`
- Do not use `msgfmt` as the default validation command. It is too narrow for
  this repo workflow and encourages bypassing the required gettext sync.

## Notes

- Do not translate generated files under `next/_build/`.
