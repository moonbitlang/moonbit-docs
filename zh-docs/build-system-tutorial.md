# MoonBit 构建系统教程

`moon` 是 MoonBit 语言的构建系统，目前基于 [n2](https://github.com/evmar/n2) 项目。`moon` 支持并行构建和增量构建，此外它还支持管理和构建 [mooncakes.io](https://mooncakes.io/) 上的第三方包。

## 准备工作

在开始之前，请确保安装好以下内容：

1. **MoonBit CLI 工具**: 从[这里](https://www.moonbitlang.cn/download/)下载。该命令行工具用于创建和管理 MoonBit 项目。

    使用 `moon help` 命令可查看使用说明。

    ```
    $ moon help
    Moonbit's build system

    Usage: moon <COMMAND>

    Commands:
      build     Build the current package
      check     Check the current package, but don't build object files
      run       Run WebAssembly module
      clean     Remove the target directory
      new       Create a new moonbit package
      bench     Generate build matrix for benchmarking
      fmt       Format moonbit
      version   Print version info and exit
      test      Run the tests
      login     Log in to your account
      register  Register an account on mooncakes.io
      publish   Publish the current package
      add       Add a new dependency
      remove    Remove a dependency
      tree      Display the dependency tree
      update    Update index
      doc       Generate documentation
      install   Install dependencies
      help      Print this message or the help of the given subcommand(s)

    Options:
      -h, --help  Print help
    ```

2. **Moonbit Language** Visual Studio Code 插件: 可以从 VS Code 市场安装。该插件为 MoonBit 提供了丰富的开发环境，包括语法高亮、代码补全等功能。

安装完成后，让我们开始创建一个新的 MoonBit 模块。

## 创建一个新模块

要创建一个新模块，请在终端中输入 `moon new` 命令，您会看到模块创建向导。如果全部使用默认值即可在 `my-project` 目录下创建一个名为 `hello` 的新模块。

```bash
$ moon new
Enter the path to create the project (. for current directory): my-project
Select the create mode: exec
Enter your username: username
Enter your project name: hello
Enter your license: Apache-2.0
Created my-project
```

## 了解模块目录结构

创建新模块后，目录结构应如下所示：

```bash
my-project
├── README.md
├── lib
│   ├── hello.mbt
│   ├── hello_test.mbt
│   └── moon.pkg.json
├── main
│   ├── main.mbt
│   └── moon.pkg.json
└── moon.mod.json
```

这里简单解释一下目录结构：

- `lib` 和 `main` 目录：这些是模块中的包。每个包可以包含多个 `.mbt` 文件，这些文件是 MoonBit 语言的源代码文件。不过，无论包中有多少个 `.mbt` 文件，它们都共享一个公共的 `moon.pkg.json` 文件。`lib/*_test.mbt` 是 `lib` 包中独立的测试文件，在这些文件中可以直接访问 `lib` 包的私有成员。这些文件只有在测试模式下才会加入到编译中，可以在这些独立测试文件中写内联测试和供测试使用的工具函数。

- `moon.pkg.json` 文件：包描述符文件。它定义了包的属性，例如该包是否为 `main` 包，以及它所导入的包。
  - `main/moon.pkg.json`：
    ```json
    {
      "is_main": true,
      "import": [
        "username/hello/lib"
      ]
    }
    ```
    其中的 `"is_main: true"` 声明此包需要被构建系统链接为 `wasm` 文件。

  - `lib/moon.pkg.json`
      ```json
      {}
      ```
    内容为空，其作用只是告诉构建系统该文件夹是一个包。

- `moon.mod.json` 用于将目录标识为 MoonBit 模块。它包含模块的名称：

  ```json
  {
    "name": "username/hello",
    "version": "0.1.0",
    "readme": "README.md",
    "repository": "",
    "license": "Apache-2.0",
    "keywords": [],
    "description": ""
  }
  ```

## 使用包

我们的 `username/hello` 模块包含两个包：`lib` 和 `main`。

- `lib` 包含 `hello.mbt` 文件与 `hello_test.mbt` 文件：

  `hello.mbt`
  ```rust
  pub fn hello() -> String {
      "Hello, world!"
  }
  ```

  `hello_test.mbt`
  ```rust
  test "hello" {
    if hello() != "Hello, world!" {
      return Err("hello() != \"Hello, world!\"")
    }
  }
  ```

- `main` 包含一个 `main.mbt` 文件：

  ```rust
  fn init {
    println(@lib.hello())
  }
  ```

要执行程序，请在 `moon run` 命令中指定 `main` 包所在的路径：

```bash
$ moon run ./main
Hello, world!
```

也可以省略 `./`

```bash
$ moon run main
Hello, world!
```

您可以使用 `moon test` 命令进行测试:

```bash
$ moon test
Total tests: 1, passed: 1, failed: 0.
```

## 包导入

在 MoonBit 的构建系统中，模块的名称用来引用其内部包。
要在 `main/main.mbt` 中导入 `lib` 包，需要在 `main/moon.pkg.json` 中指定：

```json
{
  "is_main": true,
  "import": [
    "username/hello/lib"
  ]
}
```

这里的 `username/hello/lib"` 指定了导入 `username/hello` 模块中的 `username/hello/lib` 包，这样你就能在 `main/main.mbt` 中使用 `@lib.hello()` 了。

注意，我们在 `main/moon.pkg.json` 中导入的包名是 `username/hello/lib`，在 `main/main.mbt` 中使用的是 `@lib` 来引用该包，这里的 `import` 其实是给包名 `username/hello/lib` 生成了一个默认的别名。之后你会学到如何自定义包的别名。

## 创建和使用包

首先，在 `lib` 目录下创建一个名为 `fib` 的新目录：

```bash
mkdir lib/fib
```

然后在 `lib/fib` 下创建新文件：

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
my-project
├── README.md
├── lib
│   ├── fib
│   │   ├── a.mbt
│   │   ├── b.mbt
│   │   └── moon.pkg.json
│   ├── hello.mbt
│   ├── hello_test.mbt
│   └── moon.pkg.json
├── main
│   ├── main.mbt
│   └── moon.pkg.json
└── moon.mod.json
```

在 `main/moon.pkg.json` 文件中，导入 `username/hello/lib/fib` 包，并定义其别名为 `my_awesome_fibonacci`：

```json
{
  "is_main": true,
  "import": [
    "username/hello/lib",
    {
      "path": "username/hello/lib/fib",
      "alias": "my_awesome_fibonacci"
    }
  ]
}
```

这行代码导入了 `fib` 包，它是 `hello` 模块中 `lib` 包的一部分。完成后，你可以在 `main/main.mbt` 中使用 `fib` 包。将 `main/main.mbt` 文件的内容替换为：

```rust
fn main {
  let a = @my_awesome_fibonacci.fib(10)
  let b = @my_awesome_fibonacci.fib2(11)
  println("fib(10) = \(a), fib(11) = \(b)")

  println(@lib.hello())
}
```

要执行程序，请指定主包所在的路径：

```bash
$ moon run main
fib(10) = 55, fib(11) = 89
Hello, world!
```

## 添加测试

最后，我们添加一些测试来验证我们的 `fib` 实现。在 `lib/fib/a.mbt` 中添加以下内容：

`lib/fib/a.mbt`

```rust
fn assert_eq[T: Show + Eq](lhs: T, rhs: T) -> Unit {
  if lhs != rhs {
    abort("assert_eq failed.\n    lhs: \(lhs)\n    rhs: \(rhs)")
  }
}

test {
  assert_eq(fib(1), 1)
  assert_eq(fib(2), 1)
  assert_eq(fib(3), 2)
  assert_eq(fib(4), 3)
  assert_eq(fib(5), 5)
}
```

这段代码测试了斐波那契序列的前五个项。`test { ... }` 定义了一个内联测试块。内联测试块中的代码会在测试模式下执行。

内联测试块会在非测试的编译模式下被丢弃（`moon build` 和 `moon run`），所以它们不会导致生成的代码大小膨胀。

## 独立的测试文件

除了内联测试外，MoonBit 还支持独立的测试文件。名字以 `_test.mbt` 结尾的源文件会被视作独立的测试文件。它们只有在测试模式下才会加入到编译中。我们可以在这些独立测试文件中写内联测试，以及供测试使用的工具函数。例如，可以在 `lib/fib` 目录下创建一个名为 `fib_test.mbt` 的文件，并粘贴以下代码：

`lib/fib/fib_test.mbt`:

```rust
test {
  assert_eq(fib(1), 1)
  assert_eq(fib2(2), 1)
  assert_eq(fib(3), 2)
  assert_eq(fib2(4), 3)
  assert_eq(fib(5), 5)
}
```

最后，使用 `moon test` 命令，它会扫描整个项目，识别并运行所有的内联测试以及以 `_test.mbt` 结尾的文件。如果一切正常，你将看到：

```bash
$ moon test
Total tests: 3, passed: 3, failed: 0.
$ moon test -v
test username/hello/lib/hello_test.mbt::hello ok
test username/hello/lib/fib/a.mbt::0 ok
test username/hello/lib/fib/fib_test.mbt::0 ok
Total tests: 3, passed: 3, failed: 0.
```

注意这里也执行了 `main/main.mbt:init`，后续我们将会改善测试与包初始化函数的问题。
