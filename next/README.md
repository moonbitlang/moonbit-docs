# Next gen moonbit-docs

A new MoonBit docs framework based on Sphinx.

## Develop

### Install

- For Python Environment, execute command `> Python: Create Environment` for `next` using `requirement.txt` in VSCode, or:

  ```bash
  python3 -m venv .env
  source .env/bin/activate
  pip install -r requirements.txt
  ```

- For building PDF using Latex, `latexmk` needs to be installed:
  - MacOS:
    - install [Mactex](https://www.tug.org/mactex/)
    - install `latexmk` using TeX Live Utility

### Development

Execute task `Watch Document` in VSCode, or:

```bash
sphinx-autobuild . ./_build/html
# or sphinx-autobuild -D language='zh_CN' . ./_build/html
```

### Build

Execute task `Build Document` in VSCode, or:

```bash
make html
python3 -m http.server -d _build/html
```

For Chinese version:

```bash
make -e SPHINXOPTS="-D language='zh_CN'" html
python3 -m http.server -d _build/html
```

For PDF:

```bash
make latexpdf
open ./_build/latex/moonbitdocument.pdf
```

For Markdown:

```bash
pip install sphinx-markdown-builder
make markdown
```

### Update translation template

Execute task `Translate Document` in VSCode, or:

```bash
make gettext
sphinx-intl update -p _build/gettext -l zh_CN
```