# Next gen moonbit-docs

view [README-zh.md](./README-zh.md) for Chinese version.

A new MoonBit docs framework based on Sphinx.

## Develop

You can just run `./autobuild.sh` to start the development server, it will
install the dependencies if they are not installed, and start the server on watch mode.

Below are the instructions for manual setup.

### Install

- Install `just` and `uv`, then run commands from the repository root:

  ```bash
  just --list
  ```

- For building PDF using Latex, `latexmk` needs to be installed:
  - MacOS:
    - install [Mactex](https://www.tug.org/mactex/)
    - install `latexmk` using TeX Live Utility

### Development

Execute task `Watch Document` in VSCode, or:

```bash
just docs-watch
# or just docs-watch-zh
```

### Build

Execute task `Build Document` in VSCode, or:

```bash
just docs-html
python3 -m http.server -d next/_build/html
```

For Chinese version:

```bash
just docs-html-zh
python3 -m http.server -d next/_build/html
```

For Japanese version:

```bash
just docs-html-ja
python3 -m http.server -d next/_build/html
```

For PDF:

```bash
just docs-pdf
open next/_build/latex/moonbitdocument.pdf
```

For Markdown:

```bash
just docs-markdown
```

### Update translation template

From the repository root, run:

```bash
just i18n
```

For Japanese locale catalog updates:

```bash
just i18n ja
```

This runs the same underlying Sphinx flow:

```bash
cd next
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
