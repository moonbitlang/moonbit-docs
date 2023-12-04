# MoonBit 构建系统教程

Moon 是 MoonBit 语言的构建系统，目前基于[n2](https://github.com/evmar/n2)项目。Moon 支持并行和增量构建本地包。管理和构建第三方包的功能即将推出。

## 准备工作

在开始本教程之前，请确保已安装以下内容：

1. **MoonBit CLI 工具**: 从[这里](https://www.moonbitlang.cn/download/)下载。这个命令行工具用于创建和管理 MoonBit 项目。

   使用`moon help`命令查看使用说明。

   ```
   $ moon help
   Moonbit's build system

   Usage: moon <COMMAND>

   Commands:
     build    Build the current package
     check    Check the current package, but don't build object files
     run      Run WebAssembly module
     clean    Remove the target directory
     new      Create a new moonbit package
     bench    Generate build matrix for benchmarking
     fmt      Format moonbit
     version  Print version info and exit
     test     Run the tests
     help     Print this message or the help of the given subcommand(s)

   Options:
     -h, --help  Print help
   ```

2. **Moonbit Language** Visual Studio Code 插件: 可以从 VS Code 市场安装。该插件为 MoonBit 提供了丰富的开发环境，包括语法高亮、代码补全等功能。

完成这些安装后，让我们开始在 MoonBit 中构建一个新模块。

## 创建一个新模块

要创建一个新模块，在终端中输入`moon new hello`命令：

```bash
$ moon new hello
```

该命令将创建一个名为`hello`的新模块。

## 理解模块目录结构

创建新模块后，目录结构应如下所示：

```bash
.
├── lib
│   ├── hello.mbt
│   └── moon.pkg.json
├── main
│   ├── main.mbt
│   └── moon.pkg.json
└── moon.mod.json
```

这里对目录结构进行简要解释：

- `lib`和`main`目录：这些是模块中的包。每个包可以包含多个`.mbt`文件，这些文件是 MoonBit 语言的源代码文件。不过，无论包中有多少个`.mbt`文件，它们都共享一个公共的`moon.pkg.json`文件。

- `moon.pkg.json`文件：包描述符文件。它定义了包的属性，例如该包是否为 main 包，该包所导入的包。
  - `main/moon.pkg.json`：
    ```json
    {
      "is_main": true,
      "import": {
        "hello8/lib": ""
      }
    }
    ```
    其中的 `"is_main: true"` 声明该包需要被构建系统链接为 wasm 文件。
  - `lib/moon.pkg.json`
    ```json
    {}
    ```
    内容为空，其作用仅仅是告诉构建系统该文件夹是一个包。

- `moon.mod.json`用于将目录标识为 MoonBit 模块。它包含模块的名称：

  ```
  {
    "name": "hello"
  }
  ```

## 检查项目

使用 Visual Studio Code 打开项目。在安装了 MoonBit 插件之后，在终端中使用`moon check --watch`命令自动检查项目。

![before watch](./imgs/before_watch.png)

执行`moon check --watch`之后，VS Code 应该如下所示。

![after watch](./imgs/after_watch.png)

## 使用包

我们的`hello`模块包含两个包：`lib`和`main`。

`lib`包含一个`hello.mbt`文件：

```rust
pub fn hello() -> String {
    "Hello, world!"
}
```

`main`包含一个`main.mbt`文件：

```rust
fn init {
  println(@lib.hello())
}
```

要执行程序，请指定路径到`main`包：

```bash
$ moon run ./main
Hello, world!
```

## 包导入

在 MoonBit 的构建系统中，模块的名称用于引用其内部包。
要在`main/main.mbt`中导入`lib`包，需要在`main/moon.pkg`中指定：

```json
{
  "is_main": true,
  "import": {
    "hello/lib": ""
  }
}
```

这里，`"hello/lib": ""`指定要导入`hello`模块中的`lib`包，冒号后面的空字符串 `""` 表示没有给`lib`起一个别名。

## 创建和使用包

首先，在 lib 下创建一个名为 fib 的新目录：

```bash
mkdir lib/fib
```

然后，在 `lib/fib` 下创建新文件：

`a.mbt`:

```rust
pub fn fib(n : Int) -> Int {
  match n {
    0 => 0
    1 => 1
    _ => fib(n - 1) + fib(n - 2)
  }
}
```

`b.mbt`:

```rust
pub fn fib2(num : Int) -> Int {
  fn aux(n, acc1, acc2) {
    match n {
      0 => acc1
      1 => acc2
      _ => aux(n - 1, acc2, acc1 + acc2)
    }
  }

  aux(num, 0, 1)
}
```

`moon.pkg.json`:

```json
{}
```

创建这些文件后，目录结构应如下所示：

```
.
├── lib
│   ├── fib
│   │   ├── a.mbt
│   │   ├── b.mbt
│   │   └── moon.pkg.json
│   ├── hello.mbt
│   └── moon.pkg.json
├── main
│   ├── main.mbt
│   └── moon.pkg.json
└── moon.mod.json
```

在 `main/moon.pkg.json` 文件中，导入 `hello/lib/fib` 包：

```json
{
  "is_main": true,
  "import": {
    "hello/lib": "",
    "hello/lib/fib": ""
  }
}
```

这行代码导入了 `fib` 包，它是 `hello` 模块中的 `lib` 包的一部分。完成后，你可以在 `main/main.mbt` 中使用 `fib` 包。将 `main/main.mbt` 文件的内容替换为：

```rust
fn init {
  let a = @fib.fib(10)
  let b = @fib.fib2(11)
  println("fib(10) = \(a), fib(11) = \(b)")
}
```

要执行程序，请指定主包的路径：

```bash
$ moon run ./main
fib(10) = 55, fib(11) = 89
```

## 添加测试

最后，让我们添加一些测试来验证我们的 fib 实现。

首先，在 `lib/fib` 目录下，创建一个名为 `fib_test.mbt` 的文件，并粘贴以下代码：

```rust
fn assert_eq[T: Eq](lhs: T, rhs: T) {
  if lhs != rhs {
    abort("")
  }
}

fn init {
  assert_eq(fib(1), 1)
  assert_eq(fib(2), 1)
  assert_eq(fib(3), 2)
  assert_eq(fib(4), 3)
  assert_eq(fib(5), 5)
}
```

这段代码测试了斐波那契序列的前五个项。

最后，使用 `moon test` 命令，它扫描整个项目，识别并运行所有以 `_test.mbt` 结尾的文件。如果一切正常，你将看到：

```bash
$ moon test
test lib/fib ... ok
```
