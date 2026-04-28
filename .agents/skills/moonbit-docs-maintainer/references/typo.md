# Typo And Prose Lint

Use this reference for changes involving `typos`, `autocorrect`, prose lint CI,
or typo-related ignore/config files.

## Relevant paths

- `.github/workflows/typo.yml`: CI workflow named `check examples`.
- `typos.toml`: configuration for `reviewdog/action-typos`.
- `.autocorrectrc`: rule configuration for `huacnlee/autocorrect-action`.
- `.autocorrectignore`: files ignored by AutoCorrect.

## Workflow

1. Treat typo/prose lint as a source-text check, not as a formatter for generated
   or catalog files.
2. Do not run broad autocorrect fixes over translation catalogs or generated
   files. In particular, gettext `.po` files under `next/locales/` should stay
   governed by the translation workflow.
3. If CI reports an AutoCorrect issue in a catalog or generated file, prefer an
   ignore rule over mass-editing unrelated translations.
4. If CI reports a real typo in authored docs, fix the source document and then
   run the relevant i18n sync if translations are affected.
5. Keep ignore rules narrow and explain why the ignored files are not suitable
   for prose auto-correction.

## Validation

- Local AutoCorrect lint: `autocorrect . --lint --no-diff-bg-color`
- Local typos check, when installed: `typos`

`check examples` in GitHub Actions is the typo/prose lint workflow despite its
generic name.
