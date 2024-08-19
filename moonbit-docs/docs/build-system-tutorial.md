# MoonBit's Build System Tutorial

Moon is the build system for the MoonBit language, currently based on the
[n2](https://github.com/evmar/n2) project. Moon supports parallel and
incremental builds. Additionally, moon also supports managing and building
third-party packages on [mooncakes.io](https://mooncakes.io/)

## Prerequisites

Before you begin with this tutorial, make sure you have installed the following:

1. **MoonBit CLI Tools**: Download it from the
[https://www.moonbitlang.com/download/](https://www.moonbitlang.com/download/).
This command line tool is needed for creating and managing MoonBit projects.

    Use `moon help` to view the usage instructions.

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

2. **Moonbit Language** plugin in Visual Studio Code: You can install it from
the VS Code marketplace. This plugin provides a rich development environment for
MoonBit, including must-have functionalities like syntax highlighting,
intellisense, interactive debugging, testing, and more.

Once you have these prerequisites fulfilled, let's start by creating a new
MoonBit module.

## Creating a New Module

`moon` comes with a handy module creation wizard `moon new`. The default
settings are shown below:

```plaintext
$ moon new
Enter the path to create the project (. for current directory): my-project
Select the create mode: exec
Enter your username: username
Enter your project name: hello
Enter your license: Apache-2.0
Created my-project
```

This creates a new module named `hello` in `my-project`. The word _project_ is
used interchangeably with _module_.

## Understanding MoonBit's Module Structure

A typical module/project structure resembles the following:

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

Here's a brief explanation of the structure:

- `lib` and `main` directories: These are the packages within the module. Each
package may contain multiple moonbit source files (.mbt). A common
`moon.pkg.json` is shared around every source files within that package.

- `lib/*_test.mbt` are tests for the `lib` package. However members of `lib`
aren't directly visible to the tests, you'll need to explicitly use the
`@my-project.*` to access it. Tests are only included in
test compilation, allowing inline tests and utility functions for
testing purposes to be written within these separate test files.

- `moon.pkg.json` is the package descriptor. It defines the properties of the
package, such as whether it is the main package and the packages it imports.

  - `main/moon.pkg.json`:

    ```json
    {
      "is-main": true,
      "import": [
        "username/hello/lib"
      ]
    }
    ```

  Here, `"is-main": true` declares that the package needs to be linked by the
  build system into a wasm file.
  
  - `lib/moon.pkg.json`:

    ```json
    {}
    ```

  This file is empty. Its purpose is simply to inform the build system that this
  folder is a package.
  
- `moon.mod.json` is used to declare a directory as a MoonBit module. It
contains the module's name:

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

Refer to the [json schema](./build-system-configuration.md) of module/package
descriptor for a complete specification.

## Working with Packages

Our `username/hello` module contains two packages: `lib` and `main`.

The `lib` package contains `hello.mbt` and `hello_test.mbt` files:

  `hello.mbt`

  ```moonbit -f=hello.mbt
  pub fn hello() -> String {
      "Hello, world!"
  }
  ```

  `hello_test.mbt`

  ```moonbit -f=hello.mbt
  test "hello" {
    if hello() != "Hello, world!" {
      fail!("hello() != \"Hello, world!\"")
    }
  }
  ```

The `main` package contains a `main.mbt` file:

  ```moonbit no-check
  fn main {
    println(@lib.hello())
  }
  ```

To execute the program, specify the path to the `main` package in the `moon run` command:

```bash
$ moon run main
Hello, world!
```

You can test using the `moon test` command:

```bash
$ moon test
Total tests: 1, passed: 1, failed: 0.
```

## Package Importing

MoonBit's build system uses the name of a module to reference its internal
packages. To use `lib` within `main/main.mbt`, you need to specify it in
`main/moon.pkg.json`:

```json
{
  "is_main": true,
  "import": [
    "username/hello/lib"
  ]
}
```

(Although the intellisense will do that for you: just type `@lib` then enter.)

Here, `username/hello/lib` specifies importing the `username/hello/lib` package
from the `username/hello` module, so you can use `@lib.hello()` in
`main/main.mbt`.

Note that the package name imported in `main/moon.pkg.json` is
`username/hello/lib`, and `@lib` is used to refer to this package in
`main/main.mbt`. The import here actually generates a default alias for the
package name `username/hello/lib`.

## Creating and Using a New Package

Suppose we have a new package named `fib` under `lib` and two moonbit source
`lib/fib/{a,b}.mbt`.

In `a.mbt`:

```moonbit
pub fn fib(n : Int) -> Int {
  match n {
    0 => 0
    1 => 1
    _ => fib(n - 1) + fib(n - 2)
  }
}
```

in `b.mbt`:

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

and `moon.pkg.json`:

```json
{}
```

Our project structure should look like this now:

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

In the `main/moon.pkg.json` file, import the `username/hello/lib/fib` package
and define an alias `my_awesome_fibonacci` for it:

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

In `main/main.mbt`:

```moonbit no-check
fn main {
  let a = @my_awesome_fibonacci.fib(10)
  let b = @my_awesome_fibonacci.fib2(11)
  println("fib(10) = \{a}, fib(11) = \{b}")

  println(@lib.hello())
}
```

Running `moon run main` again gives us the expected:

```bash
$ moon run main
fib(10) = 55, fib(11) = 89
Hello, world!
```

## Adding Tests

MoonBit differentiate between white-box and black-box tests. A white-box test
usually refers to an inline test block or a stand-alone `*_wbtest.mbt` source, intended for package developers to test their code,
whereas a black-box test refers to a `*_test.mbt` source, emulating package
users using current package. They may have different imports: a white-box test
automatically imports everything from `import` and `test-import` in
`moon.pkg.json`; a black-box test imports just the same as white-box but
with the addition of current package.

Let's add some inline tests to verify our fib implementation. In `lib/fib/a.mbt`:

```moonbit
fn assert_eq[T: Show + Eq](lhs: T, rhs: T) -> Unit {
  if lhs != rhs {
    abort("assert_eq failed.\n\tlhs: \{lhs}\n\trhs: \{rhs}")
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

This code tests the first five terms of the Fibonacci sequence. `test { ... }`
defines an inline test block. The code inside an inline test block is executed
in test mode.

Inline test blocks are discarded in non-test compilation modes (`moon build` and
`moon run`), so they won't cause the generated code size to bloat.

## Stand-alone test files

Stand-alone tests are included in test mode only as well. You can write inline
tests and test utilities in these stand-alone test files. For example, inside
the `lib/fib` directory, create a file named `fib_test.mbt` and paste the
following code:

`lib/fib/fib_test.mbt`

```moonbit
test {
  assert_eq(fib(1), 1)
  assert_eq(fib2(2), 1)
  assert_eq(fib(3), 2)
  assert_eq(fib2(4), 3)
  assert_eq(fib(5), 5)
}
```

Now we use the `moon test` command, which scans the entire project,
identifies, and runs all inline tests as well as files ending with `_test.mbt`
or `_wbtest.mbt`. If everything is normal, you will see:

```bash
$ moon test
Total tests: 3, passed: 3, failed: 0.
$ moon test -v
test username/hello/lib/hello_test.mbt::hello ok
test username/hello/lib/fib/a.mbt::0 ok
test username/hello/lib/fib/fib_test.mbt::0 ok
Total tests: 3, passed: 3, failed: 0.
```

Note that `main/main.mbt:init` is also executed here, and we will improve the issue of testing with package initialization functions in the future.
