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

To create a new module, enter the `moon new <path>` command in the terminal, where the path is the directory that you'd like to put the project, and you will see the module being created. By using all the default values, you can create a new module named `username/my_project` in the `my_project` directory.

```bash
$ moon new my_project
Initialized empty Git repository in my_project/.git/
Created username/my_project at my_project
```

You may also specify the username and module name by using the `--user` option and `--name` option respectively.
If you have logged-in, the username will default to your username.

## Understanding the Module Directory Structure

After creating the new module, your directory structure should resemble the following:

```bash
my_project
├── Agents.md
├── cmd
│   └── main
│       ├── main.mbt
│       └── moon.pkg.json
├── LICENSE
├── moon.mod.json
├── moon.pkg.json
├── my_project_test.mbt
├── my_project.mbt
├── README.mbt.md
└── README.md -> README.mbt.md
```

```{note}
On Windows system, you need administrator priviledge or the developer mode enabled to create the symbolic link.
```

Here's a brief explanation of the directory structure:

- `moon.mod.json` is used to identify a directory as a MoonBit module. It contains the module's metadata, such as the module name, version, etc.

  ```json
  {
    "name": "username/my_project",
    "version": "0.1.0",
    "readme": "README.md",
    "repository": "",
    "license": "Apache-2.0",
    "keywords": [],
    "description": ""
  }
  ```

- `.` and `cmd/main` directories: These are the packages within the module. Each package can contain multiple `.mbt` files, which are the source code files for the MoonBit language. However, regardless of how many `.mbt` files a package has, they all share a common `moon.pkg.json` file. `*_test.mbt` are separate test files in the package, these files are for blackbox test, so private members of the same package cannot be accessed directly.

- `moon.pkg.json` is package descriptor. It defines the properties of the package, such as whether it is the main package and the packages it imports.

  - `cmd/main/moon.pkg.json`:

    ```json
    {
      "is-main": true,
      "import": [
        {
          "path": "username/my_project",
          "alias": "lib"
        }
      ]
    }
    ```

    Here, `"is-main: true"` declares that the package contains an entry for the `moon run` command.

  - `moon.pkg.json`:

    ```json
    {}
    ```

    This file is empty. Its purpose is simply to inform the build system that this folder is a package.

- `README.mbt.md` is the README file. The code blocks written inside will be type checked and tested by `moon check` and `moon test`.

## Working with Packages

Our `username/my_project` module contains two packages: `username/my_project` and `username/my_project/cmd/main`.

The `username/my_project` package contains `my_project.mbt` and `my_project_test.mbt` files:


```{code-block} moonbit
:caption: my_project.mbt
///|
pub fn fib(n : Int) -> Int64 {
  for i = 0, a = 0L, b = 1L; i < n; i = i + 1, a = b, b = a + b {

  } else {
    b
  }
}
```

```{code-block} moonbit
:caption: my_project_test.mbt
///|
test "fib" {
  let array = [1, 2, 3, 4, 5].map(fib(_))

  // `inspect` is used to check the output of the function
  // Just write `inspect(value)` and execute `moon test --update`
  // to update the expected output, and verify them afterwards
  inspect(array, content="[1, 2, 3, 5, 8]")
}
```

```{note}
The generated file name will depend on the package name.
```

The `username/my_project/cmd/main` package contains a `main.mbt` file:

```moonbit
///|
fn main {
  println(@lib.fib(10))
}
```

To execute the program, specify the file system's path to the `username/my_project/cmd/main` package in the `moon run` command:

```bash
$ moon run cmd/main
89
```

You can test using the `moon test` command:

```bash
$ moon test
Total tests: 1, passed: 1, failed: 0.
```

## Package Importing

In the MoonBit's build system, the dependency is declared at the package level.
To import the `username/my_project` package in `username/my_project/cmd/main`, you need to specify it in `cmd/main/moon.pkg.json`:

```json
{
  "is-main": true,
  "import": [
    {
      "path": "username/my_project",
      "alias": "lib"
    }
  ]
}
```

Here, `"username/my_project` specifies importing the root package and having an alias of `lib`, so you can use `@lib.fib(10)` in `cmd/main/main.mbt`.

## Creating and Using a New Package

First, create a new directory named `fib` under `lib`:

```bash
mkdir fib
```

Now, you can create new files under `fib`:

```{code-block} moonbit
:caption: slow.mbt
pub fn fib_slow(n : Int) -> Int {
  match n {
    0 => 0
    1 => 1
    _ => fib_slow(n - 1) + fib_slow(n - 2)
  }
}
```

```{code-block} moonbit
:caption: fast.mbt
pub fn fib_fast(num : Int) -> Int {
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

```{code-block} json
:caption: moon.pkg.json
{}
```

After creating these files, your directory structure should look like this:

```bash
.
├── Agents.md
├── cmd
│   └── main
│       ├── main.mbt
│       └── moon.pkg.json
├── fib
│   ├── fast.mbt
│   ├── moon.pkg.json
│   └── slow.mbt
├── LICENSE
├── moon.mod.json
├── moon.pkg.json
├── my_project_test.mbt
├── my_project.mbt
├── README.mbt.md
└── README.md -> README.mbt.md
```

In the `cmd/main/moon.pkg.json` file, import the `username/my_project/fib` package and customize its alias to `my_awesome_fibonacci`:

```json
{
  "is_main": true,
  "import": [
    {
      "path": "username/my_project/fib",
      "alias": "my_awesome_fibonacci"
    }
  ]
}
```

This imports the `fib` package. After doing this, you can use the `fib` package in `cmd/main/main.mbt`. Replace the file content of `cmd/main/main.mbt` to:

```moonbit
fn main {
  let a = @my_awesome_fibonacci.fib_slow(10)
  let b = @my_awesome_fibonacci.fib_fast(11)
  println("fib(10) = \{a}, fib(11) = \{b}")
}
```

To execute your program, specify the path to the `main` package:

```bash
$ moon run cmd/main
fib(10) = 55, fib(11) = 89
```

## Adding Tests

Let's add some tests to verify our fib implementation. Add the following content in `fib/fib_test.mbt`:

```moonbit
test {
  inspect(fib_slow(0))
  inspect(fib_slow(1))
  inspect(fib_slow(2))
}
```

This code tests the first three terms of the Fibonacci sequence. `test { ... }` defines an inline test block. The code inside an inline test block is executed in test mode.

Inline test blocks are discarded in non-test compilation modes (`moon build` and `moon run`), so they won't cause the generated code size to bloat.

Here we are using the snapshot test. Execute `moon test --update`, and the file should be changed to:

```moonbit
test {
  inspect(@fib.fib_slow(0), content="0")
  inspect(@fib.fib_slow(1), content="1")
  inspect(@fib.fib_slow(2), content="1")
}
```

Notice that the test code uses `@fib` to refer to the `fib` package. The build system automatically creates a new package for blackbox tests by using the files that end with `_test.mbt`.

Finally, reuse the `moon test` command, which scans the entire project, identifies, and runs all the tests.
If everything is normal, you will see:

```bash
$ moon test
Total tests: 2, passed: 2, failed: 0.
```