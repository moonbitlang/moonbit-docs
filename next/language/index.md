# MoonBit Language

MoonBit is an end-to-end programming language toolchain for cloud and edge computing using WebAssembly. The IDE environment is available at [https://try.moonbitlang.com](https://try.moonbitlang.com) without any installation; it does not rely on any server either.

## Status and aimed timeline

MoonBit is currently in beta-preview. We expect to reach beta in 2024/11/22, and 1.0 in 2025.

When MoonBit reaches beta, it means any backwards-incompatible changes will be seriously evaluated and MoonBit _can_ be used in production(very rare compiler bugs). MoonBit is developed by a talented full time team who had extensive experience in building language toolchains, so we will grow much faster than the typical language ecosystem, you won't wait long to use MoonBit in your production.

## Main advantages

- Generate significantly smaller WASM output than any existing solutions.
- Much faster runtime performance.
- State of the art compile-time performance.
- Simple but practical, data-oriented language design.

## Overview

A MoonBit program consists of type definitions, function definitions, and variable bindings.

### Program entrance

There is a specialized function called `init` function. The `init` function is special in two aspects:

1. There can be multiple `init` functions in the same package.
2. An `init` function can't be explicitly called or referred to by other functions. Instead, all `init` functions will be implicitly called when initializing a package. Therefore, `init` functions should only consist of statements.

```{literalinclude} /sources/language/src/main/top.mbt
:language: moonbit
:start-after: start init
:end-before: end init
```

For WebAssembly backend, it means that it will be executed **before** the instance is available, meaning that the FFIs that relies on the instance's exportations can not be used at this stage;
for JavaScript backend, it means that it will be executed during the importation stage.

There is another specialized function called `main` function. The `main` function is the main entrance of the program, and it will be executed after the initialization stage.

```{literalinclude} /sources/language/src/main/top.mbt
:language: moonbit
:start-after: start main
:end-before: end main
```

The previous two code snippets will print the following at runtime:

```bash
1
2
```


Only packages that are `main` packages can define such `main` function. Check out [build system tutorial](/toolchain/moon/tutorial) for detail.

```{literalinclude} /sources/language/src/main/moon.pkg.json
:language: json
:caption: moon.pkg.json
```

The two functions above need to drop the parameter list and the return type.

### Expressions and Statements

MoonBit distinguishes between statements and expressions. In a function body, only the last clause should be an expression, which serves as a return value. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start expression
:end-before: end expression
```

Expressions include:

- Value literals (e.g. Boolean values, numbers, characters, strings, arrays, tuples, structs)
- Arithmetical, logical, or comparison operations
- Accesses to array elements (e.g. `a[0]`) or struct fields (e.g `r.x`) or tuple components (e.g. `t.0`)
- Variables and (capitalized) enum constructors
- Anonymous local function definitions
- `match` and `if` expressions

Statements include:

- Named local function definitions
- Local variable bindings
- Assignments
- `return` statements
- Any expression whose return type is `Unit`

```{toctree}
:hidden:
fundamentals
methods
error-handling
packages
tests
docs
ffi-and-wasm-host