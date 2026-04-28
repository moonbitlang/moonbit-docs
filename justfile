default:
    just --list

# Build the default Sphinx docs with uv-managed Python dependencies.
docs-html:
    cd next && uv run --with-requirements requirements.txt make html

# Build the Chinese Sphinx docs with uv-managed Python dependencies.
docs-html-zh:
    cd next && LANGUAGE=zh_CN uv run --with-requirements requirements.txt make html

# Build the Japanese Sphinx docs with uv-managed Python dependencies.
docs-html-ja:
    cd next && LANGUAGE=ja uv run --with-requirements requirements.txt make html

# Build the Sphinx PDF with uv-managed Python dependencies.
docs-pdf:
    cd next && uv run --with-requirements requirements.txt make latexpdf

# Build Markdown output with uv-managed Python dependencies.
docs-markdown:
    cd next && uv run --with-requirements requirements.txt make markdown

# Watch the default Sphinx docs with uv-managed Python dependencies.
docs-watch:
    cd next && uv run --with-requirements requirements.txt sphinx-autobuild . ./_build/html

# Watch the Chinese Sphinx docs with uv-managed Python dependencies.
docs-watch-zh:
    cd next && uv run --with-requirements requirements.txt sphinx-autobuild -D language='zh_CN' . ./_build/html

# Synchronize gettext templates and locale catalogs.
i18n locale="zh_CN":
    cd next && uv run --with-requirements requirements.txt make gettext
    cd next && uv run --with-requirements requirements.txt sphinx-intl update -p _build/gettext -l {{locale}}

# Check runnable MoonBit examples used by docs.
check-docs:
    uv run python scripts/check-document.py

# Check all error-code examples.
check-errors:
    uv run python next/check_error_docs.py all

# Check one error-code example, for example: just check-error 0001
check-error code:
    uv run python next/check_error_docs.py {{code}}

# Install interactive tour dependencies.
tour-install:
    cd moonbit-tour && pnpm install

# Build the interactive tour.
tour-build:
    cd moonbit-tour && pnpm build

# Run the interactive tour development server.
tour-dev:
    cd moonbit-tour && pnpm dev

# Preview the built interactive tour.
tour-preview:
    cd moonbit-tour && pnpm preview
