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
- `document.code-workspace`: VSCode tasks and dev shortcuts.

## Sphinx docs (next)
- Install deps: `python3 -m venv .env && source .env/bin/activate && pip install -r next/requirements.txt`
- Dev server: `cd next && ./autobuild.sh` or `sphinx-autobuild . ./_build/html`
- Build: `cd next && make html` (Chinese: `LANGUAGE=zh_CN make html`)

## Translation workflow (next)
- Update templates: `cd next && make gettext` then
  `sphinx-intl update -p _build/gettext -l zh_CN`
- Translate missing strings in `next/locales/zh_CN/LC_MESSAGES/*.po`.
- AI helper: `python3 next/scripts/translate_po_ai.py` (requires `OPENAI_API_KEY`).
- If `#, fuzzy` is present and the translation is verified, remove the flag.

## Checks
- `python3 scripts/check-document.py`: runs MoonBit example checks under
  `next/sources/`.
- `python3 next/check_error_docs.py all`: validates error-code examples.

## moonbit-tour
- Install/build: `cd moonbit-tour && pnpm install && pnpm build && pnpm preview`
- Dev server: `cd moonbit-tour && pnpm dev`
