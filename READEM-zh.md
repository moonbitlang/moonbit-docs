# MoonBit 文档网站

该仓库存储MoonBit的文档网站[docs.moonbitlang.cn](https://docs.moonbitlang.cn)

## 如何开始

我们使用[Docusaurus 3](https://docusaurus.io/)开发这个网站

### 安装

```bash
pnpm install
```

由于我们使用了pnpm workspace, 网站相关的代码在 `moonbit-docs` 文件夹下，所以请确保接下来的命令在 `moonbit-docs` 文件夹下执行。如果您不了解如何更改文件夹，请执行：

```bash
cd moonbit-docs
```

### 本地开发

```
pnpm start -l zh
```

这个命令会启动一个本地的开发服务器并打开一个浏览器窗口。大部分改动不需要重启服务器即可实时反映出来。

### 预览

```
pnpm build -l zh && pnpm serve
```

这个命令会完成一次生产级构建并启动一个本地服务器来预览它。

## 如何撰写文档

### 修改已有的文档

文档相关的 markdown 文件保存在`moonbit-docs/i18n/zh/docusaurus-plugin-content-docs/current`文件夹下。

### 增加新的文档

1. 在 `moonbit-docs/i18n/zh/docusaurus-plugin-content-docs/current` 文件夹下增加新的文档文件
1. 在 `moonbit-docs/docs`文件夹下增加对应的英文文档文件，如果您不了解英文，可以只留一个占位的文件。
1. 在 `moonbit-docs/sidebars.ts`文件中更新sidebar
