# Next gen moonbit-docs

查看[README.md](./README.md) 获取英文版本。

基于 Sphinx 的新一代 MoonBit 文档框架。

## 开发指南

### 安装

- 对于 Python 环境，可以在 VSCode 中执行 `> Python: Create Environment` 命令，为 `next` 项目使用 `requirement.txt` 创建环境，或者：

  ```bash
  python3 -m venv .env
  source .env/bin/activate
  pip install -r requirements.txt
  ```

- 使用 Latex 构建 PDF 时，需要安装 `latexmk`：
  - MacOS:
    - 安装 [Mactex](https://www.tug.org/mactex/)
    - 使用 TeX Live Utility 安装 `latexmk`

### 开发

在 VSCode 中执行 `Watch Document` 任务，或者：

```bash
sphinx-autobuild . ./_build/html
# 或者 sphinx-autobuild -D language='zh_CN' . ./_build/html
```

### 构建

在 VSCode 中执行 `Build Document` 任务，或者：

```bash
make html
python3 -m http.server -d _build/html
```

对于中文版本：

```bash
LANGUAGE="zh_CN" make html
python3 -m http.server -d _build/html
```

对于 PDF：

```bash
make latexpdf
open ./_build/latex/moonbitdocument.pdf
```

对于 Markdown：

```bash
pip install sphinx-markdown-builder
make markdown
```

### 更新翻译模板

在 VSCode 中执行 `Translate Document` 任务，或者：

```bash
make gettext
sphinx-intl update -p _build/gettext -l zh_CN
```