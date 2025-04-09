# Next gen moonbit-docs

view [README-zh.md](./README-zh.md) for Chinese version.

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
LANGUAGE="zh_CN" make html
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

You should be able to see the file changed thanks to the Git version system.
You should see new entries or modified entries each composed of a document position, a `msgid` and a `msgstr`.
The `msgid` is the original text and `msgstr` would be the translation to be written.

If there's a `fuzzy` flag, it means that gettext has tried to match a translation which might not be correct.
If you have verified the content or translated it otherwise, you should remove the line containing the flag.

For full format explanation, checkout [GNU's handbook](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html)

For better editing experience, checkout [editors](https://www.gnu.org/software/gettext/manual/html_node/Editing.html) listed on GNU's website.