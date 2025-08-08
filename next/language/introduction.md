# Introduction

A MoonBit program consists of top-level definitions including:

- type definitions
- function definitions
- constant definitions and variable bindings
- `init` functions, `main` function and/or `test` blocks.

## Expressions and Statements

MoonBit distinguishes between statements and expressions. In a function body, only the last clause should be an expression, which serves as a return value. For example:

```{code-block} moonbit
:class: top-level
fn foo() -> Int {
  let x = 1
  x + 1
}

fn bar() -> Int {
  let x = 1
  //! x + 1
  x + 2
}
```

Expressions include:

- Value literals (e.g. Boolean values, numbers, characters, strings, arrays, tuples, structs)
- Arithmetical, logical, or comparison operations
- Accesses to array elements (e.g. `a[0]`), struct fields (e.g `r.x`), tuple components (e.g. `t.0`), etc.
- Variables and (capitalized) enum constructors
- Anonymous local function definitions
- `match`, `if`, `loop` expressions, etc.

Statements include:

- Named local function definitions
- Local variable bindings
- Assignments
- `return` statements
- Any expression whose return type is `Unit`, (e.g. `ignore`)

A code block can contain multiple statements and one expression, and the value of the expression is the value of the code block.

## Variable Binding

A variable can be declared as mutable or immutable using `let mut` or `let`, respectively. A mutable variable can be reassigned to a new value, while an immutable one cannot.

A constant can only be declared at top level and cannot be changed.

```{code-block} moonbit
:class: top-level
let zero = 0

const ZERO = 0

fn main {
  //! const ZERO = 0 
  let mut i = 10
  i = 20
  println(i + zero + ZERO)
}
```

```{note}
A top level variable binding 
- requires **explicit** type annotation (unless defined using literals such as string, byte or numbers)
- can't be mutable (use `Ref` instead)
```


## Naming conventions

Variables, functions should start with lowercase letters `a-z` and can contain letters, numbers, underscore, and other non-ascii unicode chars.
It is recommended to name them with snake_case.

Constants, types should start with uppercase letters `A-Z` and can contain letters, numbers, underscore, and other non-ascii unicode chars.
It is recommended to name them with PascalCase or SCREAMING_SNAKE_CASE.

### Keywords

The following are the keywords and should not be used:

```json
[
  "as", "else", "extern", "fn", "fnalias", "if", "let", "const", "match", "using",
  "mut", "type", "typealias", "struct", "enum", "trait", "traitalias", "derive",
  "while", "break", "continue", "import", "return", "throw", "raise", "try", "catch",
  "pub", "priv", "readonly", "true", "false", "_", "test", "loop", "for", "in", "impl",
  "with", "guard", "async", "is", "suberror", "and", "letrec", "enumview", "noraise",
  "defer",
]
```

### Reserved Keywords

The following are the reserved keywords. Using them would introduce a warning.
They might be turned into keywords in the future.

```json
[
  "module", "move", "ref", "static", "super", "unsafe", "use", "where", "await",
  "dyn", "abstract", "do", "final", "macro", "override", "typeof", "virtual", "yield",
  "local", "method", "alias", "assert", "package", "recur", "using", "enumview",
  "isnot", "define", "downcast", "inherit", "member", "namespace", "static", "upcast",
  "use", "void", "lazy", "include", "mixin", "protected", "sealed", "constructor",
  "atomic", "volatile", "anyframe", "anytype", "asm", "await", "comptime", "errdefer",
  "export", "opaque", "orelse", "resume", "threadlocal", "unreachable", "dynclass",
  "dynobj", "dynrec", "var", "finally", "noasync",
]
```

## Program entrance

### `init` and `main`
There is a specialized function called `init` function. The `init` function is special:

1. It has no parameter list nor return type.
2. There can be multiple `init` functions in the same package.
3. An `init` function can't be explicitly called or referred to by other functions. 
Instead, all `init` functions will be implicitly called when initializing a package. Therefore, `init` functions should only consist of statements.

```{code-block} moonbit
:class: top-level
fn init {
  let x = 1
  println(x)
}
```

There is another specialized function called `main` function. The `main` function is the main entrance of the program, and it will be executed after the initialization stage.

Same as the `init` function, it has no parameter list nor return type.

```{code-block} moonbit
:class: top-level
fn main {
  let x = 2
  println(x)
}
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

### `test`

There's also a top-level structure called `test` block. A `test` block defines inline tests, such as:

```{literalinclude} /sources/language/src/test/top.mbt
:language: moonbit
:start-after: start test 1
:end-before: end test 1
```

The following contents will use `test` block and `main` function to demonstrate the execution result,
and we assume that all the `test` blocks pass unless stated otherwise.