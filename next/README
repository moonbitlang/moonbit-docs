# (WIP) Next gen moonbit-docs

A new MoonBit docs framework based on Sphinx.

## Develop

### Install

```bash
python3 -m venv .env
source .env/bin/activate
pip install -r requirements.txt
```

### Build

```bash
make html
python3 -m http.server -d _build/html
```

For Chinese version:

```bash
make -e SPHINXOPTS="-D language='zh_CN'" html
python3 -m http.server -d _build/html
```

### Update translation template

```bash
make gettext
sphinx-intl update -p _build/gettext -l zh_CN
```