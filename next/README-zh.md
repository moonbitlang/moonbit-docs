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

也可以使用辅助脚本（需要 gettext 工具 `msgmerge` 和 `msguniq`）：

```bash
python3 scripts/i18n.py all
```

其他子命令：

```bash
python3 scripts/i18n.py gettext
python3 scripts/i18n.py sync
```

你应该能够通过 Git 版本系统看到文件的变化。
你会看到新增或修改的条目，每个条目由文档位置、`msgid` 和 `msgstr` 组成。
`msgid` 是原始文本，`msgstr` 则是需要填写的翻译内容。

如果有 `fuzzy` 标记，表示 gettext 尝试匹配了一个可能不正确的翻译。
如果你已经验证了内容或者另外翻译了它，你应该删除包含该标记的行。

要了解完整的格式说明，请查看 [GNU 手册](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html)

要获得更好的编辑体验，请查看 GNU 网站上列出的[编辑器](https://www.gnu.org/software/gettext/manual/html_node/Editing.html)。
