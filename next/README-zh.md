# Next gen moonbit-docs

查看[README.md](./README.md) 获取英文版本。

基于 Sphinx 的新一代 MoonBit 文档框架。

## 开发指南

### 安装

- 安装 `just` 和 `uv`，然后在仓库根目录运行命令：

  ```bash
  just --list
  ```

- 使用 Latex 构建 PDF 时，需要安装 `latexmk`：
  - MacOS:
    - 安装 [Mactex](https://www.tug.org/mactex/)
    - 使用 TeX Live Utility 安装 `latexmk`

### 开发

在 VSCode 中执行 `Watch Document` 任务，或者：

```bash
just docs-watch
# 或者 just docs-watch-zh
```

### 构建

在 VSCode 中执行 `Build Document` 任务，或者：

```bash
just docs-html
python3 -m http.server -d next/_build/html
```

对于中文版本：

```bash
just docs-html-zh
python3 -m http.server -d next/_build/html
```

对于日文版本：

```bash
just docs-html-ja
python3 -m http.server -d next/_build/html
```

对于 PDF：

```bash
just docs-pdf
open next/_build/latex/moonbitdocument.pdf
```

对于 Markdown：

```bash
just docs-markdown
```

### 更新翻译模板

在仓库根目录运行：

```bash
just i18n
```

更新日文翻译模板：

```bash
just i18n ja
```

这个命令内部执行同样的 Sphinx 流程：

```bash
cd next
make gettext
sphinx-intl update -p _build/gettext -l zh_CN
```

你应该能够通过 Git 版本系统看到文件的变化。
你会看到新增或修改的条目，每个条目由文档位置、`msgid` 和 `msgstr` 组成。
`msgid` 是原始文本，`msgstr` 则是需要填写的翻译内容。

如果有 `fuzzy` 标记，表示 gettext 尝试匹配了一个可能不正确的翻译。
如果你已经验证了内容或者另外翻译了它，你应该删除包含该标记的行。

要了解完整的格式说明，请查看 [GNU 手册](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html)

要获得更好的编辑体验，请查看 GNU 网站上列出的[编辑器](https://www.gnu.org/software/gettext/manual/html_node/Editing.html)。
