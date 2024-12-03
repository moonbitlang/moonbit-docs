# MoonBit

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

## Functions

Functions take arguments and produce a result. In MoonBit, functions are first-class, which means that functions can be arguments or return values of other functions. MoonBit's naming convention requires that function names should not begin with uppercase letters (A-Z). Compare for constructors in the `enum` section below.

### Top-Level Functions

Functions can be defined as top-level or local. We can use the `fn` keyword to define a top-level function that sums three integers and returns the result, as follows:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start top-level functions
:end-before: end top-level functions
```

Note that the arguments and return value of top-level functions require explicit type annotations.

### Local Functions

Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 1
:end-before: end local functions 1
```

Functions, whether named or anonymous, are _lexical closures_: any identifiers without a local binding must refer to bindings from a surrounding lexical scope. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 2
:end-before: end local functions 2
```

### Function Applications

A function can be applied to a list of arguments in parentheses:

```moonbit
add3(1, 2, 7)
```

This works whether `add3` is a function defined with a name (as in the previous example), or a variable bound to a function value, as shown below:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start function application 1
:end-before: end function application 1
```

The expression `add3(1, 2, 7)` returns `10`. Any expression that evaluates to a function value is applicable:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:dedent:
:start-after: start function application 2
:end-before: end function application 2
```

### Labelled arguments

Functions can declare labelled argument with the syntax `label~ : Type`. `label` will also serve as parameter name inside function body:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start labelled arguments 1
:end-before: end labelled arguments 1
```

Labelled arguments can be supplied via the syntax `label=arg`. `label=label` can be abbreviated as `label~`:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start labelled arguments 2
:end-before: end labelled arguments 2
```

Labelled function can be supplied in any order. The evaluation order of arguments is the same as the order of parameters in function declaration.

### Optional arguments

A labelled argument can be made optional by supplying a default expression with the syntax `label~ : Type = default_expr`. If this argument is not supplied at call site, the default expression will be used:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 1
:end-before: end optional arguments 1
```

The default expression will be evaluated every time it is used. And the side effect in the default expression, if any, will also be triggered. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 2
:end-before: end optional arguments 2
```

If you want to share the result of default expression between different function calls, you can lift the default expression to a toplevel `let` declaration:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 3
:end-before: end optional arguments 3
```

Default expression can depend on the value of previous arguments. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 4
:end-before: end optional arguments 4
:emphasize-lines: 4
```

#### Automatically insert `Some` when supplying optional arguments

It is quite often optional arguments have type `T?` with `None` as default value.
In this case, passing the argument explicitly requires wrapping a `Some`,
which is ugly:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 5
:end-before: end optional arguments 5
```

Fortunately, MoonBit provides a special kind of optional arguments to solve this problem.
Optional arguments declared with `label? : T` has type `T?` and `None` as default value.
When supplying this kind of optional argument directly, MoonBit will automatically insert a `Some`:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 6
:end-before: end optional arguments 6
```

Sometimes, it is also useful to pass a value of type `T?` directly,
for example when forwarding optional argument.
MoonBit provides a syntax `label?=value` for this, with `label?` being an abbreviation of `label?=label`:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start optional arguments 7
:end-before: end optional arguments 7
```

### Autofill arguments

MoonBit supports filling specific types of arguments automatically at different call site, such as the source location of a function call.
To declare an autofill argument, simply declare an optional argument with `_` as default value.
Now if the argument is not explicitly supplied, MoonBit will automatically fill it at the call site.

Currently MoonBit supports two types of autofill arguments, `SourceLoc`, which is the source location of the whole function call,
and `ArgsLoc`, which is a array containing the source location of each argument, if any:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start autofill arguments
:end-before: end autofill arguments
```

Autofill arguments are very useful for writing debugging and testing utilities.

## Control Structures

### Conditional Expressions

A conditional expression consists of a condition, a consequent, and an optional else clause.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start conditional expressions 1
:end-before: end conditional expressions 1
```

The else clause can also contain another if-else expression:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start conditional expressions 2
:end-before: end conditional expressions 2
```

Curly brackets are used to group multiple expressions in the consequent or the else clause.

Note that a conditional expression always returns a value in MoonBit, and the return values of the consequent and the else clause must be of the same type. Here is an example:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start conditional expressions 3
:end-before: end conditional expressions 3
```

### While loop

In MoonBit, `while` loop can be used to execute a block of code repeatedly as long as a condition is true. The condition is evaluated before executing the block of code. The `while` loop is defined using the `while` keyword, followed by a condition and the loop body. The loop body is a sequence of statements. The loop body is executed as long as the condition is true.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start while loop 1
:end-before: end while loop 1
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/while_loop_1
:caption: Output
```

The loop body supports `break` and `continue`. Using `break` allows you to exit the current loop, while using `continue` skips the remaining part of the current iteration and proceeds to the next iteration.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start while loop 2
:end-before: end while loop 2
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/while_loop_2
:caption: Output
```

The `while` loop also supports an optional `else` clause. When the loop condition becomes false, the `else` clause will be executed, and then the loop will end.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start while loop 3
:end-before: end while loop 3
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/while_loop_3
:caption: Output
```

When there is an `else` clause, the `while` loop can also return a value. The return value is the evaluation result of the `else` clause. In this case, if you use `break` to exit the loop, you need to provide a return value after `break`, which should be of the same type as the return value of the `else` clause.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start while loop 4
:end-before: end while loop 4
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/while_loop_4
:caption: Output
```

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start while loop 5
:end-before: end while loop 5
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/while_loop_5
:caption: Output
```

### For Loop

MoonBit also supports C-style For loops. The keyword `for` is followed by variable initialization clauses, loop conditions, and update clauses separated by semicolons. They do not need to be enclosed in parentheses.
For example, the code below creates a new variable binding `i`, which has a scope throughout the entire loop and is immutable. This makes it easier to write clear code and reason about it:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start for loop 1
:end-before: end for loop 1
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/for_loop_1
:caption: Output
```

The variable initialization clause can create multiple bindings:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start for loop 2
:end-before: end for loop 2
```

It should be noted that in the update clause, when there are multiple binding variables, the semantics are to update them simultaneously. In other words, in the example above, the update clause does not execute `i = i + 1`, `j = j + 1` sequentially, but rather increments `i` and `j` at the same time. Therefore, when reading the values of the binding variables in the update clause, you will always get the values updated in the previous iteration.

Variable initialization clauses, loop conditions, and update clauses are all optional. For example, the following two are infinite loops:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start for loop 3
:end-before: end for loop 3
```

The `for` loop also supports `continue`, `break`, and `else` clauses. Like the `while` loop, the `for` loop can also return a value using the `break` and `else` clauses.

The `continue` statement skips the remaining part of the current iteration of the `for` loop (including the update clause) and proceeds to the next iteration. The `continue` statement can also update the binding variables of the `for` loop, as long as it is followed by expressions that match the number of binding variables, separated by commas.

For example, the following program calculates the sum of even numbers from 1 to 6:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start for loop 4
:end-before: end for loop 4
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/for_loop_4
:caption: Output
```

### `for .. in` loop

MoonBit supports traversing elements of different data structures and sequences via the `for .. in` loop syntax:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start for loop 5
:end-before: end for loop 5
```

`for .. in` loop is translated to the use of `Iter` in MoonBit's standard library. Any type with a method `.iter() : Iter[T]` can be traversed using `for .. in`.
For more information of the `Iter` type, see [Iterator](#iterator) below.

In addition to sequences of a single value, MoonBit also supports traversing sequences of two values, such as `Map`, via the `Iter2` type in MoonBit's standard library.
Any type with method `.iter2() : Iter2[A, B]` can be traversed using `for .. in` with two loop variables:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start for loop 6
:end-before: end for loop 6
```

Another example of `for .. in` with two loop variables is traversing an array while keeping track of array index:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start for loop 7
:end-before: end for loop 7
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/for_loop_7
:caption: Output
```

Control flow operations such as `return`, `break` and error handling are supported in the body of `for .. in` loop:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start for loop 8
:end-before: end for loop 8
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/for_loop_8
:caption: Output
```

If a loop variable is unused, it can be ignored with `_`.

### Functional loop

Functional loop is a powerful feature in MoonBit that enables you to write loops in a functional style.

A functional loop consumes arguments and returns a value. It is defined using the `loop` keyword, followed by its arguments and the loop body. The loop body is a sequence of clauses, each of which consists of a pattern and an expression. The clause whose pattern matches the input will be executed, and the loop will return the value of the expression. If no pattern matches, the loop will panic. Use the `continue` keyword with arguments to start the next iteration of the loop. Use the `break` keyword with arguments to return a value from the loop. The `break` keyword can be omitted if the value is the last expression in the loop body.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start for loop 9
:end-before: end for loop 9
```

### Guard Statement

The `guard` statement is used to check a specified invariant.
If the condition of the invariant is satisfied, the program continues executing
the subsequent statements and returns. If the condition is not satisfied (i.e., false),
the code in the `else` block is executed and its evaluation result is returned (the subsequent statements are skipped).

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start guard 1
:end-before: end guard 1
```

The `guard` statement also supports pattern matching: in the following example,
`getProcessedText` assumes that the input `path` points to resources that are all plain text,
and it uses the `guard` statement to ensure this invariant. Compared to using
a `match` statement, the subsequent processing of `text` can have one less level of indentation.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start guard 2
:end-before: end guard 2
```

When the `else` part is omitted, the program terminates if the condition specified
in the `guard` statement is not true or cannot be matched.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start guard 3
:end-before: end guard 3
```

## Iterator

An iterator is an object that traverse through a sequence while providing access
to its elements. Traditional OO languages like Java's `Iterator<T>` use `next()`
`hasNext()` to step through the iteration process, whereas functional languages
(JavaScript's `forEach`, Lisp's `mapcar`) provides a high-order function which
takes an operation and a sequence then consumes the sequence with that operation
being applied to the sequence. The former is called _external iterator_ (visible
to user) and the latter is called _internal iterator_ (invisible to user).

The built-in type `Iter[T]` is MoonBit's internal iterator implementation.
Almost all built-in sequential data structures have implemented `Iter`:

```{literalinclude} /sources/language/src/iter/top.mbt
:language: moonbit
:start-after: start iter 1
:end-before: end iter 1
```

Commonly used methods include:

- `each`: Iterates over each element in the iterator, applying some function to each element.
- `fold`: Folds the elements of the iterator using the given function, starting with the given initial value.
- `collect`: Collects the elements of the iterator into an array.

- `filter`: _lazy_ Filters the elements of the iterator based on a predicate function.
- `map`: _lazy_ Transforms the elements of the iterator using a mapping function.
- `concat`: _lazy_ Combines two iterators into one by appending the elements of the second iterator to the first.

Methods like `filter` `map` are very common on a sequence object e.g. Array.
But what makes `Iter` special is that any method that constructs a new `Iter` is
_lazy_ (i.e. iteration doesn't start on call because it's wrapped inside a
function), as a result of no allocation for intermediate value. That's what
makes `Iter` superior for traversing through sequence: no extra cost. MoonBit
encourages user to pass an `Iter` across functions instead of the sequence
object itself.

Pre-defined sequence structures like `Array` and its iterators should be
enough to use. But to take advantages of these methods when used with a custom
sequence with elements of type `S`, we will need to implement `Iter`, namely, a function that returns
an `Iter[S]`. Take `Bytes` as an example:

```{literalinclude} /sources/language/src/iter/top.mbt
:language: moonbit
:start-after: start iter 2
:end-before: end iter 2
```

Almost all `Iter` implementations are identical to that of `Bytes`, the only
main difference being the code block that actually does the iteration.

### Implementation details

The type `Iter[T]` is basically a type alias for `((T) -> IterResult) -> IterResult`,
a higher-order function that takes an operation and `IterResult` is an enum
object that tracks the state of current iteration which consists any of the 2
states:

- `IterEnd`: marking the end of an iteration
- `IterContinue`: marking the end of an iteration is yet to be reached, implying the iteration will still continue at this state.

To put it simply, `Iter[T]` takes a function `(T) -> IterResult` and use it to
transform `Iter[T]` itself to a new state of type `IterResult`. Whether that
state being `IterEnd` `IterContinue` depends on the function.

Iterator provides a unified way to iterate through data structures, and they
can be constructed at basically no cost: as long as `fn(yield)` doesn't
execute, the iteration process doesn't start.

Internally a `Iter::run()` is used to trigger the iteration. Chaining all sorts
of `Iter` methods might be visually pleasing, but do notice the heavy work
underneath the abstraction.

Thus, unlike an external iterator, once the iteration starts
there's no way to stop unless the end is reached. Methods such as `count()`
which counts the number of elements in a iterator looks like an `O(1)` operation
but actually has linear time complexity. Carefully use iterators or
performance issue might occur.

## Built-in Data Structures

### Boolean

MoonBit has a built-in boolean type, which has two values: `true` and `false`. The boolean type is used in conditional expressions and control structures.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start boolean 1
:end-before: end boolean 1
```

### Number

MoonBit have integer type and floating point type:

| type     | description                                       | example                    |
| -------- | ------------------------------------------------- | -------------------------- |
| `Int`    | 32-bit signed integer                             | `42`                       |
| `Int64`  | 64-bit signed integer                             | `1000L`                    |
| `UInt`   | 32-bit unsigned integer                           | `14U`                      |
| `UInt64` | 64-bit unsigned integer                           | `14UL`                     |
| `Double` | 64-bit floating point, defined by IEEE754         | `3.14`                     |
| `Float`  | 32-bit floating point                             | `(3.14 : Float)`           |
| `BigInt` | represents numeric values larger than other types | `10000000000000000000000N` |

MoonBit also supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- There is nothing surprising about decimal numbers.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 1
  :end-before: end number 1
  ```

- A binary number has a leading zero followed by a letter "B", i.e. `0b`/`0B`.
  Note that the digits after `0b`/`0B` must be `0` or `1`.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 2
  :end-before: end number 2
  ```

- An octal number has a leading zero followed by a letter "O", i.e. `0o`/`0O`.
  Note that the digits after `0o`/`0O` must be in the range from `0` through `7`:

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 3
  :end-before: end number 3
  ```

- A hexadecimal number has a leading zero followed by a letter "X", i.e. `0x`/`0X`.
  Note that the digits after the `0x`/`0X` must be in the range `0123456789ABCDEF`.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 4
  :end-before: end number 4
  ```

#### Overloaded int literal

When the expected type is known, MoonBit can automatically overload integer literal, and there is no need to specify the type of number via letter postfix:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start number 5
:end-before: end number 5
```

### String

`String` holds a sequence of UTF-16 code units. You can use double quotes to create a string, or use `#|` to write a multi-line string.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 1
:end-before: end string 1
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/string_1
:caption: Output
```

In double quotes string, a backslash followed by certain special characters forms an escape sequence:

| escape sequences     | description                                          |
| -------------------- | ---------------------------------------------------- |
| `\n`,`\r`,`\t`,`\b`  | New line, Carriage return, Horizontal tab, Backspace |
| `\\`                 | Backslash                                            |
| `\x41`               | Hexadecimal escape sequence                          |
| `\o102`              | Octal escape sequence                                |
| `\u5154`,`\u{1F600}` | Unicode escape sequence                              |

MoonBit supports string interpolation. It enables you to substitute variables within interpolated strings. This feature simplifies the process of constructing dynamic strings by directly embedding variable values into the text. Variables used for string interpolation must support the `to_string` method.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 3
:end-before: end string 3
```

Multi-line strings do not support interpolation by default, but you can enable interpolation for a specific line by changing the leading `#|` to `$|`:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start string 4
:end-before: end string 4
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/string_4
:caption: Output
```

### Char

`Char` is an integer representing a Unicode code point.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start char 1
:end-before: end char 1
```

### Byte(s)

A byte literal in MoonBit is either a single ASCII character or a single escape enclosed in single quotes `'`, and preceded by the character `b`. Byte literals are of type `Byte`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start byte 1
:end-before: end byte 1
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/byte_1
:caption: Output
```

A `Bytes` is a sequence of bytes. Similar to byte, bytes literals have the form of `b"..."`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start byte 2
:end-before: end byte 2
```

### Tuple

A tuple is a collection of finite values constructed using round brackets `()` with the elements separated by commas `,`. The order of elements matters; for example, `(1,true)` and `(true,1)` have different types. Here's an example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start tuple 1
:end-before: end tuple 1
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/builtin/__snapshot__/tuple_1
:caption: Output
```

Tuples can be accessed via pattern matching or index:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start tuple 2
:end-before: end tuple 2
```

### Array

An array is a finite sequence of values constructed using square brackets `[]`, with elements separated by commas `,`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array 1
:end-before: end array 1
```

You can use `numbers[x]` to refer to the xth element. The index starts from zero.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array 2
:end-before: end array 2
```

### Map

MoonBit provides a hash map data structure that preserves insertion orde called `Map` in its standard library.
`Map`s can be created via a convenient literal syntax:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start map 1
:end-before: end map 1
```

Currently keys in map literal syntax must be constant. `Map`s can also be destructed elegantly with pattern matching, see [Map Pattern](#map-pattern).

### Json literal

MoonBit supports convenient json handling by overloading literals.
When the expected type of an expression is `Json`, number, string, array and map literals can be directly used to create json data:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start json 1
:end-before: end json 1
```

Json values can be pattern matched too, see [Json Pattern](#json-pattern).

## Variable Binding

A variable can be declared as mutable or immutable using `let mut` or `let`, respectively. A mutable variable can be reassigned to a new value, while an immutable one cannot.

```{literalinclude} /sources/language/src/variable/top.mbt
:language: moonbit
```

## Data Types

There are two ways to create new data types: `struct` and `enum`.

### Struct

In MoonBit, structs are similar to tuples, but their fields are indexed by field names. A struct can be constructed using a struct literal, which is composed of a set of labeled values and delimited with curly brackets. The type of a struct literal can be automatically inferred if its fields exactly match the type definition. A field can be accessed using the dot syntax `s.f`. If a field is marked as mutable using the keyword `mut`, it can be assigned a new value.

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start struct 1
:end-before: end struct 1
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start struct 2
:end-before: end struct 2
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/struct_1
:caption: Output
```

#### Constructing Struct with Shorthand

If you already have some variable like `name` and `email`, it's redundant to repeat those names when constructing a struct. You can use shorthand instead, it behaves exactly the same:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start struct 3
:end-before: end struct 3
```

#### Struct Update Syntax

It's useful to create a new struct based on an existing one, but with some fields updated.

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start struct 4
:end-before: end struct 4
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/struct_4
:caption: Output
```

### Enum

Enum types are similar to algebraic data types in functional languages. Users familiar with C/C++ may prefer calling it tagged union.

An enum can have a set of cases (constructors). Constructor names must start with capitalized letter. You can use these names to construct corresponding cases of an enum, or checking which branch an enum value belongs to in pattern matching:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 1
:end-before: end enum 1
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start enum 2
:end-before: end enum 2
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 3
:end-before: end enum 3
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_3
:caption: Output
```

Enum cases can also carry payload data. Here's an example of defining an integer list type using enum:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 4
:end-before: end enum 4
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start enum 5
:end-before: end enum 5
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 6
:end-before: end enum 6
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_6
:caption: Output
```

#### Constructor with labelled arguments

Enum constructors can have labelled argument:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 7
:end-before: end enum 7
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start enum 8
:end-before: end enum 8
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 9
:end-before: end enum 9
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_9
:caption: Output
```

It is also possible to access labelled arguments of constructors like accessing struct fields in pattern matching:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 10
:end-before: end enum 10
```

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 11
:end-before: end enum 11
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/enum_11
:caption: Output
```

#### Constructor with mutable fields

It is also possible to define mutable fields for constructor. This is especially useful for defining imperative data structures:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start enum 12
:end-before: end enum 12
```

### Newtype

MoonBit supports a special kind of enum called newtype:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start newtype 1
:end-before: end newtype 1
```

Newtypes are similar to enums with only one constructor (with the same name as the newtype itself). So, you can use the constructor to create values of newtype, or use pattern matching to extract the underlying representation of a newtype:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start newtype 2
:end-before: end newtype 2
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/newtype_2
:caption: Output
```

Besides pattern matching, you can also use `._` to extract the internal representation of newtypes:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start newtype 3
:end-before: end newtype 3
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/data/__snapshot__/newtype_3
:caption: Output
```

### Type alias
MoonBit supports type alias via the syntax `typealias Name = TargetType`:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start typealias 1
:end-before: end typealias 1
```

unlike all other kinds of type declaration above, type alias does not define a new type,
it is merely a type macro that behaves exactly the same as its definition.
So for example one cannot define new methods or implement traits for a type alias.

Type alias can be used to perform incremental code refactor.
For example, if you want to move a type `T` from `@pkgA` to `@pkgB`,
you can leave a type alias `typealias T = @pkgB.T` in `@pkgA`, and **incrementally** port uses of `@pkgA.T` to `@pkgB.T`.
The type alias can be removed after all uses of `@pkgA.T` is migrated to `@pkgB.T`.

## Pattern Matching

We have shown a use case of pattern matching for enums, but pattern matching is not restricted to enums. For example, we can also match expressions against Boolean values, numbers, characters, strings, tuples, arrays, and struct literals. Since there is only one case for those types other than enums, we can pattern match them using `let` binding instead of `match` expressions. Note that the scope of bound variables in `match` is limited to the case where the variable is introduced, while `let` binding will introduce every variable to the current scope. Furthermore, we can use underscores `_` as wildcards for the values we don't care about, use `..` to ignore remaining fields of struct or elements of array.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 1
:end-before: end pattern 1
```

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:start-after: start pattern 2
:end-before: end pattern 2
```

There are some other useful constructs in pattern matching. For example, we can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 3
:end-before: end pattern 3
```

### Range Pattern
For builtin integer types and `Char`, MoonBit allows matching whether the value falls in a specific range.
Range patterns have the form `a..<b` or `a..=b`, where `..<` means the upper bound is exclusive, and `..=` means inclusive upper bound.
`a` and `b` can be one of:

- literal
- named constant declared with `const`
- `_`, meaning the pattern has no restriction on this side

Here are some examples:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 4
:end-before: end pattern 4
```

### Map Pattern

MoonBit allows convenient matching on map-like data structures.
Inside a map pattern, the `key : value` syntax will match if `key` exists in the map, and match the value of `key` with pattern `value`.
The `key? : value` syntax will match no matter `key` exists or not, and `value` will be matched against `map[key]` (an optional).

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 5
:end-before: end pattern 5
```

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V`.
- Currently, the key part of map pattern must be a constant
- Map patterns are always open: unmatched keys are silently ignored
- Map pattern will be compiled to efficient code: every key will be fetched at most once

### Json Pattern

When the matched value has type `Json`, literal patterns can be used directly:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 6
:end-before: end pattern 6
```

## Operators

### Operator Overloading

MoonBit supports operator overloading of builtin operators via methods. The method name corresponding to a operator `<op>` is `op_<op>`. For example:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 1
:end-before: end operator 1
```

Another example about `op_get` and `op_set`:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 2
:end-before: end operator 2
```

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start operator 3
:end-before: end operator 3
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/operator/__snapshot__/operator_3
:caption: Output
```

Currently, the following operators can be overloaded:

| Operator Name         | Method Name  |
| --------------------- | ------------ |
| `+`                   | `op_add`     |
| `-`                   | `op_sub`     |
| `*`                   | `op_mul`     |
| `/`                   | `op_div`     |
| `%`                   | `op_mod`     |
| `=`                   | `op_equal`   |
| `<<`                  | `op_shl`     |
| `>>`                  | `op_shr`     |
| `-` (unary)           | `op_neg`     |
| `_[_]` (get item)     | `op_get`     |
| `_[_] = _` (set item) | `op_set`     |
| `_[_:_]` (view)       | `op_as_view` |

### Pipe operator

MoonBit provides a convenient pipe operator `|>`, which can be used to chain regular function calls:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 4
:end-before: end operator 4
```

### Cascade Operator

The cascade operator `..` is used to perform a series of mutable operations on
the same value consecutively. The syntax is as follows:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 5
:end-before: end operator 5
```

`x..f()..g()` is equivalent to `{x.f(); x.g(); x}`.

Consider the following scenario: for a `StringBuilder` type that has methods
like `write_string`, `write_char`, `write_object`, etc., we often need to perform
a series of operations on the same `StringBuilder` value:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 6
:end-before: end operator 6
```

To avoid repetitive typing of `builder`, its methods are often designed to
return `self` itself, allowing operations to be chained using the `.` operator.
To distinguish between immutable and mutable operations, in MoonBit,
for all methods that return `Unit`, cascade operator can be used for
consecutive operations without the need to modify the return type of the methods.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 7
:end-before: end operator 7
```

### Bitwise Operator

MoonBit supports C-Style bitwise operators.

| Operator | Perform |
| -------- | ------- |
| `&`      | `land`  |
| `\|`     | `lor`   |
| `^`      | `lxor`  |
| `<<`     | `op_shl`   |
| `>>`     | `op_shr`   |

## Error Handling

### Error types

The error values used in MoonBit must have an error type. An error type can be
defined in the following forms:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 1
:end-before: end error 1
```

The return type of a function can include an error type to indicate that the
function might return an error. For example, the following function `div` might
return an error of type `DivError`:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 2
:end-before: end error 2
```

Here, the keyword `raise` is used to interrupt the function execution and return
an error.

### The Default Error Type

MoonBit provides a default error type `Error` that can be used when the concrete
error type is not important. For convenience, you can annotate the function name
or the return type with the suffix `!` to indicate that the `Error` type is
used. For example, the following function signatures are equivalent:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 3
:end-before: end error 3
```

For anonymous function and matrix function, you can annotate the keyword `fn`
with the `!` suffix to achieve that. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 4
:end-before: end error 4
```

As shown in the above example, the error types defined by `type!` can be used as
value of the type `Error` when the error is raised.

Note that only error types or the type `Error` can be used as errors. For
functions that are generic in the error type, you can use the `Error` bound to
do that. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 5
:end-before: end error 5
```

Since the type `Error` can include multiple error types, pattern matching on the
`Error` type must use the wildcard `_` to match all error types. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 6
:end-before: end error 6
```

### Handling Errors

There are three ways to handle errors:

- Append `!` after the function name in a function application to rethrow the
  error directly in case of an error, for example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 7
:end-before: end error 7
```

- Append `?` after the function name to convert the result into a first-class
  value of the `Result` type, for example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 8
:end-before: end error 8
```

- Use `try` and `catch` to catch and handle errors, for example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 9
:end-before: end error 9
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/error/__snapshot__/error_9
:caption: Output
```

Here, `try` is used to call a function that might throw an error, and `catch` is
used to match and handle the caught error. If no error is caught, the catch
block will not be executed and the `else` block will be executed instead.

The `else` block can be omitted if no action is needed when no error is caught.
For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 10
:end-before: end error 10
```

The `catch` keyword is optional, and when the body of `try` is a simple
expression, the curly braces can be omitted. For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 11
:end-before: end error 11
```

The `!` and `?` attributes can also be used on method invocation and pipe
operator. For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 12
:end-before: end error 12
```

However for infix operators such as `+` `*` that may raise an error,
the original form has to be used, e.g. `x.op_add!(y)`, `x.op_mul!(y)`.

Additionally, if the return type of a function includes an error type, the
function call must use `!` or `?` for error handling, otherwise the compiler
will report an error.

### Error Inference

Within a `try` block, several different kinds of errors can be raised. When that
happens, the compiler will use the type `Error` as the common error type.
Accordingly, the handler must use the wildcard `_` to make sure all errors are
caught. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 13
:end-before: end error 13
```

You can also use `catch!` to rethrow the uncaught errors for convenience. This
is useful when you only want to handle a specific error and rethrow others. For
example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 14
:end-before: end error 14
```

## Generics

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `List` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```{literalinclude} /sources/language/src/generics/top.mbt
:language: moonbit
```

## Access Control

By default, all function definitions and variable bindings are _invisible_ to other packages.
You can use the `pub` modifier before toplevel `let`/`fn` to make them public.

There are four different kinds of visibility for types in MoonBit:

- private type, declared with `priv`, completely invisible to the outside world
- abstract type, which is the default visibility for types. Only the name of an abstract type is visible outside, the internal representation of the type is hidden
- readonly types, declared with `pub(readonly)`. The internal representation of readonly types are visible outside,
but users can only read the values of these types from outside, construction and mutation are not allowed
- fully public types, declared with `pub(all)`. The outside world can freely construct, modify and read values of these types

Currently, the semantic of `pub` is `pub(all)`. But in the future, the meaning of `pub` will be ported to `pub(readonly)`.
In addition to the visibility of the type itself, the fields of a public `struct` can be annotated with `priv`,
which will hide the field from the outside world completely.
Note that `struct`s with private fields cannot be constructed directly outside,
but you can update the public fields using the functional struct update syntax.

Readonly types is a very useful feature, inspired by [private types](https://v2.ocaml.org/manual/privatetypes.html) in OCaml. In short, values of `pub(readonly)` types can be destructed by pattern matching and the dot syntax, but cannot be constructed or mutated in other packages. Note that there is no restriction within the same package where `pub(readonly)` types are defined.

<!-- MANUAL CHECK -->

```moonbit
// Package A
pub(readonly) struct RO {
  field: Int
}
test {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
fn println(r : RO) -> Unit {
  println("{ field: ")
  println(r.field)  // OK
  println(" }")
}
test {
  let r : RO = { field: 4 }  // ERROR: Cannot create values of the public read-only type RO!
  let r = { ..r, field: 8 }  // ERROR: Cannot mutate a public read-only field!
}
```

Access control in MoonBit adheres to the principle that a `pub` type, function, or variable cannot be defined in terms of a private type. This is because the private type may not be accessible everywhere that the `pub` entity is used. MoonBit incorporates sanity checks to prevent the occurrence of use cases that violate this principle.

<!-- MANUAL CHECK -->
```moonbit
pub struct S {
  x: T1  // OK
  y: T2  // OK
  z: T3  // ERROR: public field has private type `T3`!
}

// ERROR: public function has private parameter type `T3`!
pub fn f1(_x: T3) -> T1 { T1::A(0) }
// ERROR: public function has private return type `T3`!
pub fn f2(_x: T1) -> T3 { T3::A(0) }
// OK
pub fn f3(_x: T1) -> T1 { T1::A(0) }

pub let a: T3  // ERROR: public variable has private type `T3`!
```

## Method system

MoonBit supports methods in a different way from traditional object-oriented languages. A method in MoonBit is just a toplevel function associated with a type constructor. Methods can be defined using the syntax `fn TypeName::method_name(...) -> ...`:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method 1
:end-before: end method 1
```

As a convenient shorthand, when the first parameter of a function is named `self`, MoonBit automatically defines the function as a method of the type of `self`:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method 2
:end-before: end method 2
```

is equivalent to:

```{literalinclude} /sources/language/src/method2/top.mbt
:language: moonbit
:start-after: start method 3
:end-before: end method 3
```

Methods are just regular functions owned by a type constructor. So when there is no ambiguity, methods can be called using regular function call syntax directly:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:dedent:
:start-after: start method 4
:end-before: end method 4
```

Unlike regular functions, methods support overloading: different types can define methods of the same name. If there are multiple methods of the same name (but for different types) in scope, one can still call them by explicitly adding a `TypeName::` prefix:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:dedent:
:start-after: start method 5
:end-before: end method 5
```

When the first parameter of a method is also the type it belongs to, methods can be called using dot syntax `x.method(...)`. MoonBit automatically finds the correct method based on the type of `x`, there is no need to write the type name and even the package name of the method:

```{literalinclude} /sources/language/src/method/top.mbt
:language: moonbit
:start-after: start method 1
:end-before: end method 1
```

```{literalinclude} /sources/language/src/method2/top.mbt
:language: moonbit
:caption: using package with alias list
:start-after: start method 6
:end-before: end method 6
:emphasize-lines: 5
```

The highlighted line is only possible when there is no ambiguity in `@list`.

## View

Analogous to `slice` in other languages, the view is a reference to a
specific segment of collections. You can use `data[start:end]` to create a
view of array `data`, referencing elements from `start` to `end` (exclusive).
Both `start` and `end` indices can be omitted.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start view 1
:end-before: end view 1
```

By implementing `op_as_view` method, you can also create a view for a user-defined type. Here is an example:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start view 2
:end-before: end view 2
```

## Trait system

MoonBit features a structural trait system for overloading/ad-hoc polymorphism. Traits declare a list of operations, which must be supplied when a type wants to implement the trait. Traits can be declared as follows:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 1
:end-before: end trait 1
```

In the body of a trait definition, a special type `Self` is used to refer to the type that implements the trait.

To implement a trait, a type must provide all the methods required by the trait.
Implementation for trait methods can be provided via the syntax `impl Trait for Type with method_name(...) { ... }`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 2
:end-before: end trait 2
```

Type annotation can be omitted for trait `impl`: MoonBit will automatically infer the type based on the signature of `Trait::method` and the self type.

The author of the trait can also define default implementations for some methods in the trait, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 3
:end-before: end trait 3
```

Implementers of trait `I` don't have to provide an implementation for `f_twice`: to implement `I`, only `f` is necessary.
They can always override the default implementation with an explicit `impl I for Type with f_twice`, if desired, though.

If an explicit `impl` or default implementation is not found, trait method resolution falls back to regular methods.
This allows types to implement a trait implicitly, hence allowing different packages to work together without seeing or depending on each other.
For example, the following trait is automatically implemented for builtin number types such as `Int` and `Double`:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 4
:end-before: end trait 4
```

When declaring a generic function, the type parameters can be annotated with the traits they should implement, allowing the definition of constrained generic functions. For example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 5
:end-before: end trait 5
```

Without the `Number` requirement, the expression `x * x` in `square` will result in a method/operator not found error. Now, the function `square` can be called with any type that implements `Number`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 6
:end-before: end trait 6
```

MoonBit provides the following useful builtin traits:

<!-- MANUAL CHECK https://github.com/moonbitlang/core/blob/80cf250d22a5d5eff4a2a1b9a6720026f2fe8e38/builtin/traits.mbt -->

```moonbit
trait Eq {
  op_equal(Self, Self) -> Bool
}

trait Compare : Eq {
  // `0` for equal, `-1` for smaller, `1` for greater
  compare(Self, Self) -> Int
}

trait Hash {
  hash(Self) -> Int
}

trait Show {
  // writes a string representation of `Self` into a `Logger`
  output(Self, Logger) -> Unit
  to_string(Self) -> String
}

trait Default {
  default() -> Self
}
```

### Invoke trait methods directly
Methods of a trait can be called directly via `Trait::method`. MoonBit will infer the type of `Self` and check if `Self` indeed implements `Trait`, for example:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 7
:end-before: end trait 7
```

Trait implementations can also be invoked via dot syntax, with the following restrictions:

1. if a regular method is present, the regular method is always favored when using dot syntax
2. only trait implementations that are located in the package of the self type can be invoked via dot syntax
   - if there are multiple trait methods (from different traits) with the same name available, an ambiguity error is reported
3. if neither of the above two rules apply, trait `impl`s in current package will also be searched for dot syntax.
   This allows extending a foreign type locally.
   - these `impl`s can only be called via dot syntax locally, even if they are public.

The above rules ensures that MoonBit's dot syntax enjoys good property while being flexible.
For example, adding a new dependency never break existing code with dot syntax due to ambiguity.
These rules also make name resolution of MoonBit extremely simple:
the method called via dot syntax must always come from current package or the package of the type!

Here's an example of calling trait `impl` with dot syntax:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 8
:end-before: end trait 8
```

## Access control of methods and trait implementations

To make the trait system coherent (i.e. there is a globally unique implementation for every `Type: Trait` pair),
and prevent third-party packages from modifying behavior of existing programs by accident,
MoonBit employs the following restrictions on who can define methods/implement traits for types:

- _only the package that defines a type can define methods for it_. So one cannot define new methods or override old methods for builtin and foreign types.
- _only the package of the type or the package of the trait can define an implementation_.
  For example, only `@pkg1` and `@pkg2` are allowed to write `impl @pkg1.Trait for @pkg2.Type`.

The second rule above allows one to add new functionality to a foreign type by defining a new trait and implementing it.
This makes MoonBit's trait & method system flexible while enjoying good coherence property.

## Visibility of traits and sealed traits
There are four visibility for traits, just like `struct` and `enum`: private, abstract, readonly and fully public.
Private traits are declared with `priv trait`, and they are completely invisible from outside.
Abstract trait is the default visibility. Only the name of the trait is visible from outside, and the methods in the trait are not exposed.
Readonly traits are declared with `pub(readonly) trait`, their methods can be involked from outside, but only the current package can add new implementation for readonly traits.
Finally, fully public traits are declared with `pub(open) trait`, they are open to new implementations outside current package, and their methods can be freely used.
Currently, `pub trait` defaults to `pub(open) trait`. But in the future, the semantic of `pub trait` will be ported to `pub(readonly)`.

Abstract and readonly traits are sealed, because only the package defining the trait can implement them.
Implementing a sealed (abstract or readonly) trait outside its package result in compiler error.
If you are the owner of a sealed trait, and you want to make some implementation available to users of your package,
make sure there is at least one declaration of the form `impl Trait for Type with ...` in your package.
Implementations with only regular method and default implementations will not be available outside.

Here's an example of abstract trait:

<!-- MANUAL CHECK -->
```moonbit
trait Number {
 op_add(Self, Self) -> Self
 op_sub(Self, Self) -> Self
}

fn add[N : Number](x : X, y: X) -> X {
  Number::op_add(x, y)
}

fn sub[N : Number](x : X, y: X) -> X {
  Number::op_sub(x, y)
}

impl Number for Int with op_add(x, y) { x + y }
impl Number for Int with op_sub(x, y) { x - y }

impl Number for Double with op_add(x, y) { x + y }
impl Number for Double with op_sub(x, y) { x - y }
```

From outside this package, users can only see the following:

```moonbit
trait Number

fn op_add[N : Number](x : N, y : N) -> N
fn op_sub[N : Number](x : N, y : N) -> N

impl Number for Int
impl Number for Double
```

The author of `Number` can make use of the fact that only `Int` and `Double` can ever implement `Number`,
because new implementations are not allowed outside.

## Automatically derive builtin traits

MoonBit can automatically derive implementations for some builtin traits:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait 9
:end-before: end trait 9
```

## Trait objects

MoonBit supports runtime polymorphism via trait objects.
If `t` is of type `T`, which implements trait `I`,
one can pack the methods of `T` that implements `I`, together with `t`,
into a runtime object via `t as I`.
Trait object erases the concrete type of a value,
so objects created from different concrete types can be put in the same data structure and handled uniformly:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait object 1
:end-before: end trait object 1
```

Not all traits can be used to create objects.
"object-safe" traits' methods must satisfy the following conditions:

- `Self` must be the first parameter of a method
- There must be only one occurrence of `Self` in the type of the method (i.e. the first parameter)

Users can define new methods for trait objects, just like defining new methods for structs and enums:

```{literalinclude} /sources/language/src/trait/top.mbt
:language: moonbit
:start-after: start trait object 2
:end-before: end trait object 2
```

## Test Blocks

MoonBit provides the test code block for writing test cases. For example:

```{literalinclude} /sources/language/src/test/top.mbt
:language: moonbit
:start-after: start test 1
:end-before: end test 1
```

A test code block is essentially a function that returns a `Unit` but may throws a `String` on error, or `Unit!String` as one would see in its signature at the position of return type. It is called during the execution of `moon test` and outputs a test report through the build system. The `assert_eq` function is from the standard library; if the assertion fails, it prints an error message and terminates the test. The string `"test_name"` is used to identify the test case and is optional. If it starts with `"panic"`, it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```{literalinclude} /sources/language/src/test/top.mbt
:language: moonbit
:start-after: start test 2
:end-before: end test 2
```

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`,`let`,`enum`,`struct`,`type`. The doc comments contains a markdown text and several pragmas.

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc string 1
:end-before: end doc string 1
```

### Pragmas

Pragmas are annotations inside doc comments. They all take the form `/// @word ...`. The _word_ indicates the type of pragma and is followed optionally by several _word_ or string literals. Pragmas do not normally affect the meaning of programs. Unrecognized pragmas will be reported as warnings.

- Alert Pragmas

  Alert pragmas in doc comments of functions will be reported when those functions are referenced. This mechanism is a generalized way to mark functions as `deprecated` or `unsafe`.

  It takes the form `@alert category "alert message..."`.

  The category can be an arbitrary identifier. It allows configuration to decide which alerts are enabled or turned into errors.

  <!-- MANUAL CHECK -->
  ```moonbit
  /// @alert deprecated "Use foo2 instead"
  pub fn foo() -> Unit {
    ...
  }

  /// @alert unsafe "Div will cause an error when y is zero"
  pub fn div(x : Int, y : Int) -> Int {
    ...
  }

  test {
    foo() // warning: Use foo2 instead
    div(1, 2) |> ignore // warning: Div will cause an error when y is zero
  }
  ```

## Special Syntax

### TODO syntax

The `todo` syntax (`...`) is a special construct used to mark sections of code that are not yet implemented or are placeholders for future functionality. For example:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start todo 1
:end-before: end todo 1
```