# Sphinx Docs

Use this reference for changes under `next/` that affect the Sphinx
documentation site.

## Relevant paths

- `next/index.md`: top-level docs entry.
- `next/conf.py`: Sphinx configuration and extensions.
- `next/language/`, `next/tutorial/`, `next/toolchain/`, `next/pilot/`:
  documentation sections.
- `next/imgs/`, `next/_static/`, `imgs/`: image and static assets.
- `next/sources/`: runnable MoonBit examples referenced from docs.

## Workflow

1. Inspect nearby pages for heading style, code block style, and cross-reference
   patterns.
2. For examples embedded in prose, check whether a runnable source exists under
   `next/sources/` and keep both in sync.
3. When adding pages, update the relevant `toctree` or index page.
4. Avoid editing generated output under `next/_build/`.

## Build commands

- Development server: `just docs-watch`
- Chinese development server: `just docs-watch-zh`
- HTML build: `just docs-html`
- Chinese HTML build: `just docs-html-zh`
- PDF build: `just docs-pdf`
- Markdown build: `just docs-markdown`
- Manual development server: `cd next && sphinx-autobuild . ./_build/html`
- Manual HTML build: `cd next && make html`
- Manual Chinese HTML build: `cd next && LANGUAGE=zh_CN make html`
- Markdown build, when needed: install `sphinx-markdown-builder`, then
  `cd next && make markdown`

## Notes

- Dependencies are documented in `next/requirements.txt`.
- If Sphinx is unavailable, report that validation could not run and include the
  attempted command.
- If a docs change affects translations, update source docs first; translation
  catalog synchronization belongs to `translation.md`.
