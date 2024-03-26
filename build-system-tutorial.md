# MoonBit's Build System Tutorial

Moon is the build system for the MoonBit language, currently based on the [n2](https://github.com/evmar/n2) project. Moon supports parallel and incremental builds. Additionally, moon also supports managing and building third-party packages on [mooncakes.io](https://mooncakes.io/)

## Prerequisites

Before you begin with this tutorial, make sure you have installed the following:

1. **MoonBit CLI Tools**: Download it from the [https://www.moonbitlang.com/download/](https://www.moonbitlang.com/download/). This command line tool is needed for creating and managing MoonBit projects.

    Use `moon help` to view the usage instructions.

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
2. **Moonbit Language** plugin in Visual Studio Code: You can install it from the VS Code marketplace. This plugin provides a rich development environment for MoonBit, including functionalities like syntax highlighting, code completion, and more.

Once you have these prerequisites fulfilled, let's start by creating a new MoonBit module.

## Creating a New Module

To create a new module, enter the `moon new` command in the terminal, and you will see the module creation wizard. By using all the default values, you can create a new module named `hello` in the `my-project` directory.

```bash
$ moon new
Enter the path to create the project (. for current directory): my-project
Select the create mode: exec
Enter your username: username
Enter your project name: hello
Enter your license: Apache-2.0
Created my-project
```

## Understanding the Module Directory Structure

After creating the new module, your directory structure should resemble the following:

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

Here's a brief explanation of the directory structure:

- `lib` and `main` directories: These are the packages within the module. Each package can contain multiple `.mbt` files, which are the source code files for the MoonBit language. However, regardless of how many `.mbt` files a package has, they all share a common `moon.pkg.json` file. `lib/*_test.mbt` are separate test files in the `lib` package, where private members of the `lib` package can be accessed directly. These files are only included in the compilation in test mode, allowing for inline tests and utility functions for testing purposes to be written within these separate test files.

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

  Here, "is_main: true" declares that the package needs to be linked by the build system into a wasm file.

  - `lib/moon.pkg.json`:

    ```json
    {}
    ```

  This file is empty. Its purpose is simply to inform the build system that this folder is a package.

- `moon.mod.json` is used to identify a directory as a MoonBit module. It contains the module's name:

  ```json
  {
    "name": "hello"
  }
  ```

## Working with Packages

Our `username/hello` module contains two packages: `lib` and `main`.

The `lib` package contains `hello.mbt` and `hello_test.mbt` files:

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
      abort("")
    }
  }
  ```

The `main` package contains a `main.mbt` file:

  ```rust
  fn init {
    println(@lib.hello())
  }
  ```

To execute the program, specify the path to the `main` package in the `moon run` command:

```bash
$ moon run ./main
Hello, world!
```

You can also omit `./`

```bash
$ moon run main
Hello, world!
```


## Package Importing

In the MoonBit's build system, a module's name is used to reference its internal packages.
To import the `lib` package in `main/main.mbt`, you need to specify it in `main/moon.pkg.json`:

```json
{
  "is_main": true,
  "import": [
    "username/hello/lib"
  ]
}
```

Here, `username/hello/lib` specifies importing the `username/hello/lib` package from the `username/hello` module, so you can use `@lib.hello()` in `main/main.mbt`.

Note that the package name imported in `main/moon.pkg.json` is `username/hello/lib`, and `@lib` is used to refer to this package in `main/main.mbt`. The import here actually generates a default alias for the package name `username/hello/lib`. In the following sections, you will learn how to customize the alias for a package.

## Creating and Using a New Package

First, create a new directory named `fib` under `lib`:

```bash
mkdir lib/fib
```

Now, you can create new files under `lib/fib`:

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

After creating these files, your directory structure should look like this:

```bash
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

In the `main/moon.pkg.json` file, import the `username/hello/lib/fib` package and customize its alias to `my_awesome_fibonacci`:

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

```rust
fn init {
  let a = @my_awesome_fibonacci.fib(10)
  let b = @my_awesome_fibonacci.fib2(11)
  println("fib(10) = \(a), fib(11) = \(b)")
  
  println(@lib.hello())
}
```

To execute your program, specify the path to the `main` package:

```bash
$ moon run main
fib(10) = 55, fib(11) = 89
Hello, world!
```

## Adding Tests

Let's add some tests to verify our fib implementation. Add the following content in `lib/fib/a.mbt`:

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

This code tests the first five terms of the Fibonacci sequence. `test { ... }` defines an inline test block. The code inside an inline test block is executed in test mode.

Inline test blocks are discarded in non-test compilation modes (`moon build` and `moon run`), so they won't cause the generated code size to bloat.

## Stand-alone test files

Besides inline tests, MoonBit also supports stand-alone test files. Source files ending in `_test.mbt` are considered stand-alone test files. They will be included in test mode only. You can write inline tests and test utilities in these stand-alone test files. For example, inside the `lib/fib` directory, create a file named `fib_test.mbt` and paste the following code:

`lib/fib/fib_test.mbt`
```rust
test {
  assert_eq(fib(1), 1)
  assert_eq(fib2(2), 1)
  assert_eq(fib(3), 2)
  assert_eq(fib2(4), 3)
  assert_eq(fib(5), 5)
}
```

Finally, use the `moon test` command, which scans the entire project, identifies, and runs all inline tests as well as files ending with `_test.mbt`. If everything is normal, you will see:

```bash
$ moon test
test lib/fib ... ok
test lib ... ok
fib(10) = 55, fib(11) = 89
Hello, world!
test main ... ok
```

Note that `main/main.mbt:init` is also executed here, and we will improve the issue of testing with package initialization functions in the future.