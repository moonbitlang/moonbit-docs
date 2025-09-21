# 模块与包的使用

在 MoonBit 中，代码通过模块和包进行组织，以促进代码复用和可维护性。与许多现代编程语言类似，MoonBit 也提供了两个重要工具来协助开发：构建系统和包管理平台。

* 构建系统 `moon` 帮助你管理项目依赖、构建流程，并将模块发布到包管理平台。你可以在 [MoonBit 构建系统教程](https://docs.moonbitlang.com/zh-cn/latest/toolchain/moon/tutorial.html) 中找到相关教程。

* 包管理平台 [mooncakes.io](https://mooncakes.io) 用于查找、分享和浏览包文档。**标准库 API 文档 [`moonbitlang/core`](https://mooncakes.io/docs/moonbitlang/core) 也作为常规模块托管在该网站上。**

本教程不详细介绍如何使用 `moon` 或 mooncakes.io。更多信息请参考上述链接。不必担心——只有在开发 MoonBit 项目时才需要这些工具，你可以先继续本教程，稍后再探索它们。

## 通过 `@path/to/pkg.Func` 语法访问 API

以下是你需要了解的一些基本信息：

* 模块（module）
    模块是可以作为依赖引入到程序中的最小单元。  
    一个模块可以包含多个包，并且可以发布到 mooncakes.io。  
    每个模块都有唯一的路径，例如 `moonbitlang/core` 或 `moonbitlang/x` 。

* 包（package）
    包是模块的一部分。它隐藏实现细节，并向外部暴露有用的 API。  
    每个包也有唯一的路径，以其模块路径为前缀，例如 `moonbitlang/core/math` 。

在你将某个模块（如 `moonbitlang/x` ）作为依赖引入，并导入你想使用的包（如 `moonbitlang/x/fs` ）后，可以通过 `@path/to/pkg.func` 语法访问其函数。例如，使用 `@moonbitlang/x/fs.create_dir` （或如果你为其指定了别名，则可用 `@fs.create_dir` ）来调用 `create_dir` 函数。

**注意**： `moonbitlang/core` 模块比较特殊——它会被默认添加为依赖，并自动导入其包。
