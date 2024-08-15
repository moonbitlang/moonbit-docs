# MoonBit 构建系统教程

`moon` 是 MoonBit 语言的构建系统，目前基于 [n2](https://github.com/evmar/n2) 项目。`moon` 支持并行构建和增量构建，此外它还支持管理和构建 [mooncakes.io](https://mooncakes.io/) 上的第三方包。

## 准备工作

在开始之前，请确保安装好以下内容：

1. **MoonBit CLI 工具**: 从[这里](https://www.moonbitlang.cn/download/)下载。该命令行工具用于创建和管理 MoonBit 项目。

    使用 `moon help` 命令可查看使用说明。

    ```plaintext
    $ moon help
    The build system and package manager for MoonBit.

    Usage: moon [OPTIONS] <COMMAND>

    Commands:
      new                    Create a new moonbit package
      build                  Build the current package
      check                  Check the current package, but don't build object files
      run                    Run WebAssembly module
      test                   Test the current package
      clean                  Clean the target directory
      fmt                    Format moonbit source code
      doc                    Generate documentation
      info                   Generate public interface (`.mbti`) files for all packages in the module
      add                    Add a dependency
      remove                 Remove a dependency
      install                Install dependencies
      tree                   Display the dependency tree
      login                  Log in to your account
      register               Register an account at mooncakes.io
      publish                Publish the current package
      update                 Update the package registry index
      coverage               Code coverage utilities
      generate-build-matrix  Generate build matrix for benchmarking (legacy feature)
      upgrade                Upgrade toolchains
      shell-completion       Generate shell completion for bash/elvish/fish/pwsh/zsh to stdout
      version                Print version info and exit
      help                   Print this message or the help of the given subcommand(s)

    Options:
      -C, --directory <SOURCE_DIR>   The source code directory. Defaults to the current directory
          --target-dir <TARGET_DIR>  The target directory. Defaults to `source_dir/target`
      -q, --quiet                    Suppress output
      -v, --verbose                  Increase verbosity
          --trace                    Trace the execution of the program
          --dry-run                  Do not actually run the command
      -h, --help                     Print help
    ```

2. **Moonbit Language** Visual Studio Code 插件: 可以从 VS Code 市场安装。该插件为 MoonBit 提供了丰富的开发环境，包括语法高亮、代码补全、交互式除错和测试等功能。

安装完成后，让我们开始创建一个新的 MoonBit 模块。

## 创建一个新模块

`moon` 附带一个 `moon new` 模块创建向导。默认的配置是：

```plaintext
$ moon new
Enter the path to create the project (. for current directory): my-project
Select the create mode: exec
Enter your username: username
Enter your project name: hello
Enter your license: Apache-2.0
Created my-project
```

向导会在 `my-project` 下创建一个新模块 `hello`。项目一词在这里与模块是互通的。

## 了解模块目录结构

典型的模块/项目结构如下所示：

```plaintext
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

- `lib` 和 `main` 目录：这些是模块中的包。每个包可以包含多个 MoonBit 源文件（.mbt）。一个包中的所有源码都共享一个 `moon.pkg.json`。

- `lib/*_test.mbt` 是 `lib` 包中独立的测试文件。但 `lib` 的成员对测试是不可见的，需要显式地用 `@my-project.*` 来访问成员。这些文件只有在测试模式下才会编译，可以在这些独立测试文件中写内联测试和供测试使用的工具函数。

- `moon.pkg.json`：包描述文件，定义了包的属性，例如该包是否为 `main` 包，以及它所导入的包。
  - `main/moon.pkg.json`：

    ```json
    {
      "is-main": true,
      "import": [
        "username/hello/lib"
      ]
    }
    ```

    其中的 `"is-main": true` 声明此包需要被构建系统链接为 `wasm` 文件。

  - `lib/moon.pkg.json`

      ```json
      {}
      ```

    内容为空，其作用只是告诉构建系统该文件夹是一个包。

- `moon.mod.json` 用于将目录标记为 MoonBit 模块。它包含模块的名称：

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

模块/包描述文件的 [json schema](./build-system-configuration.md) 给出了全面的定义规范。

## 如何使用包

我们的 `username/hello` 模块包含两个包：`lib` 和 `main`。

- `lib` 包含 `hello.mbt` 文件与 `hello_test.mbt` 文件：

  `hello.mbt`

  ```moonbit
  pub fn hello() -> String {
      "Hello, world!"
  }
  ```

  `hello_test.mbt`

  ```moonbit
  test "hello" {
    if hello() != "Hello, world!" {
      return Err("hello() != \"Hello, world!\"")
    }
  }
  ```

`main` 包含一个 `main.mbt` 文件：

  ```moonbit
  fn main {
    println(@lib.hello())
  }
  ```

要执行代码，为 `moon run` 命令指定 `main` 包所在的路径：

```bash
$ moon run main
Hello, world!
```

可以使用 `moon test` 命令进行测试:

```bash
$ moon test
Total tests: 1, passed: 1, failed: 0.
```

## 如何导入包

MoonBit 构建系统使用模块的名称用来引用其内部包。
要在 `main/main.mbt` 中导入 `lib` 包，需要在 `main/moon.pkg.json` 中指定：

```json
{
  "is_main": true,
  "import": [
    "username/hello/lib"
  ]
}
```

这里的 `username/hello/lib"` 指定导入 `username/hello` 模块中的 `username/hello/lib` 包，因此得以在 `main/main.mbt` 中使用 `@lib.hello()` 。

注意，我们在 `main/moon.pkg.json` 中导入的包名是 `username/hello/lib`，在 `main/main.mbt` 中使用 `@lib` 来引用该包，这里的 `import` 其实是给包名 `username/hello/lib` 生成了一个默认的别名。

## 创建和使用包

考虑在 `lib` 下创建一个新包 `fib`，并新建两个源码文件 `lib/fib/{a,b}.mbt`。

`a.mbt`：

```moonbit
pub fn fib(n : Int) -> Int {
  match n {
    0 => 0
    1 => 1
    _ => fib(n - 1) + fib(n - 2)
  }
}
```

`b.mbt`：

```moonbit
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

`moon.pkg.json`：

```json
{}
```

现在项目结构应该如下所示：

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

修改 `main/moon.pkg.json`，导入 `username/hello/lib/fib` 包，并定义其别名为 `my_awesome_fibonacci`：

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

`main/main.mbt`：

```moonbit
fn main {
  let a = @my_awesome_fibonacci.fib(10)
  let b = @my_awesome_fibonacci.fib2(11)
  println("fib(10) = \(a), fib(11) = \(b)")

  println(@lib.hello())
}
```

运行 `moon run main` 能给出预期结果：

```bash
$ moon run main
fib(10) = 55, fib(11) = 89
Hello, world!
```

## 添加测试

MoonBit 区分白盒、黑盒测试。白盒测试指的是内联测试或一个独立的 `*_wbtest.mbt` 文件，模拟包开发者的测试场景；黑盒测试指的是 `*_test.mbt` 文件，模拟用户使用当前包的场景。
可以为这两种测试导入不同的包：白盒测试会导入 `moon.pkg.json` 中的 `import` `test-import` 字段；黑盒测试则比白盒测试多导入一个当前包。

不妨为 `fib` 添加一些内联测试来验证其正确性。`lib/fib/a.mbt`：

```moonbit
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

MoonBit 还支持独立的测试文件，这些文件只有在测试模式下才会加入到编译中。
可以在这些独立测试文件中写内联测试，以及供测试使用的工具函数。例如可以在
`lib/fib` 目录下创建一个名为 `fib_test.mbt` 的文件：

`lib/fib/fib_test.mbt`:

```moonbit
test {
  assert_eq(fib(1), 1)
  assert_eq(fib2(2), 1)
  assert_eq(fib(3), 2)
  assert_eq(fib2(4), 3)
  assert_eq(fib(5), 5)
}
```

现在可以用 `moon test`，扫描整个项目，识别并运行所有的内联测试以及所有以 `_test.mbt`/ `_wbtest.mbt` 结尾的文件。如果没有问题则输出：

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
