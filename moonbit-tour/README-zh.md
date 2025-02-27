# MoonBit Language Tour

查看该文件的英文版本：[English version](./README.md)

一个用于学习 MoonBit 编程语言的交互式教程。

## 开始

```sh
pnpm install
pnpm build
pnpm preview
```

打开 <http://localhost:3000> 查看 tour 网站。

## 如何添加新的教程

### 添加新的教程

1. 设置开发环境。

   ```sh
   pnpm install
   pnpm dev
   ```

1. 打开 <http://localhost:8080> 查看 tour 网站。

1. 在章节文件夹下创建一个新的文件夹，遵循命名惯例 `lesson<n>_<lesson-name>` (从 1 开始计数)。

1. 在创建的文件夹下编写教程内容（`index.md`），并编写教程代码（`index.mbt`）。

### 添加新的章节

1. 在 `tour` 文件夹下创建一个新的文件夹，遵循命名惯例 `chapter<n>_<chapter-name>`。
1. 按照上述步骤添加新的教程。

## 致谢

该项目深受 [Gleam Language Tour](https://github.com/gleam-lang/language-tour) 启发。
