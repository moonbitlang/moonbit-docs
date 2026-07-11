default:
    just --list

# Build the default Sphinx docs with uv-managed Python dependencies.
docs-html:
    cd next && uv run --with-requirements requirements.txt make html

# Build and validate the self-contained MoonBit semantic snapshot.
# The snapshot argument is relative to the repository root.
semantic-index snapshot="semantic-snapshot":
    uv run python scripts/build_semantic_snapshot.py build --repo-root . --output "{{ snapshot }}"

# Validate an existing semantic snapshot without rebuilding it.
semantic-check snapshot="semantic-snapshot":
    uv run python scripts/build_semantic_snapshot.py validate --snapshot "{{ snapshot }}"

# Validate that a deployment snapshot is complete and contains real semantics.
semantic-check-required snapshot="semantic-snapshot":
    uv run python scripts/build_semantic_snapshot.py validate --snapshot "{{ snapshot }}" --require-semantics --require-external-definitions

# Build one locale from an existing snapshot and verify the rendered semantics.
docs-html-semantic-from-snapshot snapshot="semantic-snapshot" language="" builddir="next/_build":
    just semantic-check-required "{{ snapshot }}"
    cd next && LANGUAGE="{{ language }}" MOONBIT_SEMANTIC_SNAPSHOT="{{ justfile_directory() }}/{{ snapshot }}" MOONBIT_SEMANTIC_REQUIRED=1 uv run --with-requirements requirements.txt make clean html BUILDDIR="{{ justfile_directory() }}/{{ builddir }}" SPHINXOPTS="-j auto"
    just semantic-html-check "{{ snapshot }}" "{{ builddir }}/html"

# Production HTML entrypoint: index once, then build one strict locale.
docs-html-semantic snapshot="semantic-snapshot" language="" builddir="next/_build":
    just semantic-index "{{ snapshot }}"
    just docs-html-semantic-from-snapshot "{{ snapshot }}" "{{ language }}" "{{ builddir }}"

# Build strict Chinese HTML at the normal deployment output path.
docs-html-semantic-zh snapshot="semantic-snapshot" builddir="next/_build":
    just docs-html-semantic "{{ snapshot }}" "zh_CN" "{{ builddir }}"

# Build strict Japanese HTML at the normal deployment output path.
docs-html-semantic-ja snapshot="semantic-snapshot" builddir="next/_build":
    just docs-html-semantic "{{ snapshot }}" "ja" "{{ builddir }}"

# Build all deployed locales from one shared snapshot for CI/local inspection.
docs-html-semantic-all snapshot="semantic-snapshot":
    just semantic-index "{{ snapshot }}"
    just docs-html-semantic-from-snapshot "{{ snapshot }}" "" "next/_build"
    just docs-html-semantic-from-snapshot "{{ snapshot }}" "zh_CN" "next/_build/zh_CN"
    just docs-html-semantic-from-snapshot "{{ snapshot }}" "ja" "next/_build/ja"

# Check that generated HTML contains closed Hover and Definition data.
semantic-html-check snapshot="semantic-snapshot" html="next/_build/html":
    MOONBIT_SEMANTIC_E2E=1 MOONBIT_SEMANTIC_SNAPSHOT="{{ snapshot }}" MOONBIT_SEMANTIC_HTML="{{ html }}" uv run --with-requirements next/requirements.txt python -m unittest discover -s tests/semantic_docs -p 'test_integration*.py' -v

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
