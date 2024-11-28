# MoonBit's Build System Tutorial

Moon is the build system for the MoonBit language, currently based on the [n2](https://github.com/evmar/n2) project. Moon supports parallel and incremental builds. Additionally, moon also supports managing and building third-party packages on [mooncakes.io](https://mooncakes.io/)

## Prerequisites

Before you begin with this tutorial, make sure you have installed the following:

1. **MoonBit CLI Tools**: Download it from the <https://www.moonbitlang.com/download/>. This command line tool is needed for creating and managing MoonBit projects.

    Use `moon help` to view the usage instructions.

    ```bash
    $ moon help
    ...
    ```

2. **MoonBit Language** plugin in Visual Studio Code: You can install it from the VS Code marketplace. This plugin provides a rich development environment for MoonBit, including functionalities like syntax highlighting, code completion, and more.

Once you have these prerequisites fulfilled, let's start by creating a new MoonBit module.

## Creating a New Module

To create a new module, enter the `moon new` command in the terminal, and you will see the module creation wizard. By using all the default values, you can create a new module named `username/hello` in the `my-project` directory.

```bash
$ moon new
Enter the path to create the project (. for current directory): my-project
Select the create mode: exec
Enter your username: username
Enter your project name: hello
Enter your license: Apache-2.0
Created my-project
```

> If you want use all default values, you can use `moon new my-project` to create a new module named `username/hello` in the `my-project` directory.

## Understanding the Module Directory Structure

After creating the new module, your directory structure should resemble the following:

```bash
my-project
├── LICENSE
├── README.md
├── moon.mod.json
└── src
    ├── lib
    │   ├── hello.mbt
    │   ├── hello_test.mbt
    │   └── moon.pkg.json
    └── main
        ├── main.mbt
        └── moon.pkg.json
```

Here's a brief explanation of the directory structure:

- `moon.mod.json` is used to identify a directory as a MoonBit module. It contains the module's metadata, such as the module name, version, etc. `source` specifies the source directory of the module. The default value is `src`.

  ```json
  {
    "name": "username/hello",
    "version": "0.1.0",
    "readme": "README.md",
    "repository": "",
    "license": "Apache-2.0",
    "keywords": [],
    "description": "",
    "source": "src"
  }
  ```

- `lib` and `main` directories: These are the packages within the module. Each package can contain multiple `.mbt` files, which are the source code files for the MoonBit language. However, regardless of how many `.mbt` files a package has, they all share a common `moon.pkg.json` file. `lib/*_test.mbt` are separate test files in the `lib` package, these files are for blackbox test, so private members of the `lib` package cannot be accessed directly.

- `moon.pkg.json` is package descriptor. It defines the properties of the package, such as whether it is the main package and the packages it imports.

  - `main/moon.pkg.json`:

    ```json
    {
      "is_main": true,
      "import": [
        "username/hello/lib"
      ]
    }
    ```

  Here, `"is_main: true"` declares that the package needs to be linked by the build system into a wasm file.

  - `lib/moon.pkg.json`:

    ```json
    {}
    ```

  This file is empty. Its purpose is simply to inform the build system that this folder is a package.

## Working with Packages

Our `username/hello` module contains two packages: `username/hello/lib` and `username/hello/main`.

The `username/hello/lib` package contains `hello.mbt` and `hello_test.mbt` files:

  `hello.mbt`

  ```moonbit
  pub fn hello() -> String {
      "Hello, world!"
  }
  ```

  `hello_test.mbt`

  ```moonbit
  test "hello" {
    if @lib.hello() != "Hello, world!" {
      fail!("@lib.hello() != \"Hello, world!\"")
    }
  }
  ```

The `username/hello/main` package contains a `main.mbt` file:

  ```moonbit
  fn main {
    println(@lib.hello())
  }
  ```

To execute the program, specify the file system's path to the `username/hello/main` package in the `moon run` command:

```bash
$ moon run ./src/main
Hello, world!
```

You can also omit `./`

```bash
$ moon run src/main
Hello, world!
```

You can test using the `moon test` command:

```bash
$ moon test
Total tests: 1, passed: 1, failed: 0.
```

## Package Importing

In the MoonBit's build system, a module's name is used to reference its internal packages.
To import the `username/hello/lib` package in `src/main/main.mbt`, you need to specify it in `src/main/moon.pkg.json`:

```json
{
  "is_main": true,
  "import": [
    "username/hello/lib"
  ]
}
```

Here, `username/hello/lib` specifies importing the `username/hello/lib` package from the `username/hello` module, so you can use `@lib.hello()` in `main/main.mbt`.

Note that the package name imported in `src/main/moon.pkg.json` is `username/hello/lib`, and `@lib` is used to refer to this package in `src/main/main.mbt`. The import here actually generates a default alias for the package name `username/hello/lib`. In the following sections, you will learn how to customize the alias for a package.

## Creating and Using a New Package

First, create a new directory named `fib` under `lib`:

```bash
mkdir src/lib/fib
```

Now, you can create new files under `src/lib/fib`:

`a.mbt`:

```moonbit
pub fn fib(n : Int) -> Int {
  match n {
    0 => 0
    1 => 1
    _ => fib(n - 1) + fib(n - 2)
  }
}
```

`b.mbt`:

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

`moon.pkg.json`:

```json
{}
```

After creating these files, your directory structure should look like this:

```bash
my-project
├── LICENSE
├── README.md
├── moon.mod.json
└── src
    ├── lib
    │   ├── fib
    │   │   ├── a.mbt
    │   │   ├── b.mbt
    │   │   └── moon.pkg.json
    │   ├── hello.mbt
    │   ├── hello_test.mbt
    │   └── moon.pkg.json
    └── main
        ├── main.mbt
        └── moon.pkg.json
```

In the `src/main/moon.pkg.json` file, import the `username/hello/lib/fib` package and customize its alias to `my_awesome_fibonacci`:

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

This line imports the `fib` package, which is part of the `lib` package in the `hello` module. After doing this, you can use the `fib` package in `main/main.mbt`. Replace the file content of `main/main.mbt` to:

```moonbit
fn main {
  let a = @my_awesome_fibonacci.fib(10)
  let b = @my_awesome_fibonacci.fib2(11)
  println("fib(10) = \{a}, fib(11) = \{b}")

  println(@lib.hello())
}
```

To execute your program, specify the path to the `main` package:

```bash
$ moon run ./src/main
fib(10) = 55, fib(11) = 89
Hello, world!
```

## Adding Tests

Let's add some tests to verify our fib implementation. Add the following content in `src/lib/fib/a.mbt`:

`src/lib/fib/a.mbt`

```moonbit
test {
  assert_eq!(fib(1), 1)
  assert_eq!(fib(2), 1)
  assert_eq!(fib(3), 2)
  assert_eq!(fib(4), 3)
  assert_eq!(fib(5), 5)
}
```

This code tests the first five terms of the Fibonacci sequence. `test { ... }` defines an inline test block. The code inside an inline test block is executed in test mode.

Inline test blocks are discarded in non-test compilation modes (`moon build` and `moon run`), so they won't cause the generated code size to bloat.

## Stand-alone test files for blackbox tests

Besides inline tests, MoonBit also supports stand-alone test files. Source files ending in `_test.mbt` are considered test files for blackbox tests. For example, inside the `src/lib/fib` directory, create a file named `fib_test.mbt` and paste the following code:

`src/lib/fib/fib_test.mbt`

```moonbit
test {
  assert_eq!(@fib.fib(1), 1)
  assert_eq!(@fib.fib2(2), 1)
  assert_eq!(@fib.fib(3), 2)
  assert_eq!(@fib.fib2(4), 3)
  assert_eq!(@fib.fib(5), 5)
}
```

Notice that the test code uses `@fib` to refer to the `username/hello/lib/fib` package. The build system automatically creates a new package for blackbox tests by using the files that end with `_test.mbt`. This new package will import the current package automatically, allowing you to use `@lib` in the test code.

Finally, use the `moon test` command, which scans the entire project, identifies, and runs all inline tests as well as files ending with `_test.mbt`. If everything is normal, you will see:

```bash
$ moon test
Total tests: 3, passed: 3, failed: 0.
$ moon test -v
test username/hello/lib/hello_test.mbt::hello ok
test username/hello/lib/fib/a.mbt::0 ok
test username/hello/lib/fib/fib_test.mbt::0 ok
Total tests: 3, passed: 3, failed: 0.
```