# Fundamentals

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
| `Int16`  | 16-bit signed integer                             | `(42 : Int16)`             |
| `Int`    | 32-bit signed integer                             | `42`                       |
| `Int64`  | 64-bit signed integer                             | `1000L`                    |
| `UInt16` | 16-bit unsigned integer                           | `(14 : UInt16)`            |
| `UInt`   | 32-bit unsigned integer                           | `14U`                      |
| `UInt64` | 64-bit unsigned integer                           | `14UL`                     |
| `Double` | 64-bit floating point, defined by IEEE754         | `3.14`                     |
| `Float`  | 32-bit floating point                             | `(3.14 : Float)`           |
| `BigInt` | represents numeric values larger than other types | `10000000000000000000000N` |

MoonBit also supports numeric literals, including decimal, binary, octal, and hexadecimal numbers.

To improve readability, you may place underscores in the middle of numeric literals such as `1_000_000`. Note that underscores can be placed anywhere within a number, not just every three digits.

- Decimal numbers can have underscore between the numbers. 

  By default, an int literal is signed 32-bit number. For unsigned numbers, a postfix `U` is needed; for 64-bit numbers, a postfix `L` is needed.

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

- A floating-point number literal is 64-bit floating-point number. To define a float, type annotation is needed.

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 6
  :end-before: end number 6
  ```

  A 64-bit floating-point number can also be defined using hexadecimal format:

  ```{literalinclude} /sources/language/src/builtin/top.mbt
  :language: moonbit
  :dedent:
  :start-after: start number 7
  :end-before: end number 7
  ```

#### Overloaded literal

When the expected type is known, MoonBit can automatically overload literal, and there is no need to specify the type of number via letter postfix:

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

`Char` represents a Unicode code point.

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

A `Bytes` is an immutable sequence of bytes. Similar to byte, bytes literals have the form of `b"..."`. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start byte 2
:end-before: end byte 2
```

A `@buffer.T` is a constructor for bytes that comes with methods for writing different kinds of data. For example:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start buffer 1
:end-before: end buffer 1
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

### Ref

A `Ref[T]` is a mutable reference containing a value `val` of type `T`.

It can be constructed using `{ val : x }`, and can be accessed using `ref.val`. See [struct](#struct) for detailed explanation.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start ref 1
:end-before: end ref 1
```

### Option and Result

`Option` and `Result` are the most common types to represent a possible error or failure in MoonBit.

- `Option[T]` represents a possibly missing value of type `T`. It can be abbreviated as `T?`.
- `Result[T, E]` represents either a value of type `T` or an error of type `E`.

See [enum](#enum) for detailed explanation.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start option result 1
:end-before: end option result 1
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

There are `Array[T]` and `FixedArray[T]`:

- `Array[T]` can grow in size, while
- `FixedArray[T]` has a fixed size, thus it needs to be created with initial value.

``````{warning}
A common pitfall is creating `FixedArray` with the same initial value:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array pitfall
:end-before: end array pitfall
```

This is because all the cells reference to the same object (the `FixedArray[Int]` in this case). One should use `FixedArray::makei()` instead which creates an object for each index.

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:dedent:
:start-after: start array pitfall solution
:end-before: end array pitfall solution
```
``````

When the expected type is known, MoonBit can automatically overload array, otherwise
`Array[T]` is created:

```{literalinclude} /sources/language/src/builtin/top.mbt
:language: moonbit
:start-after: start array 3
:end-before: end array 3
```

#### ArrayView

Analogous to `slice` in other languages, the view is a reference to a
specific segment of collections. You can use `data[start:end]` to create a
view of array `data`, referencing elements from `start` to `end` (exclusive).
Both `start` and `end` indices can be omitted.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:start-after: start view 1
:end-before: end view 1
```

### Map

MoonBit provides a hash map data structure that preserves insertion order called `Map` in its standard library.
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

## Functions

Functions take arguments and produce a result. In MoonBit, functions are first-class, which means that functions can be arguments or return values of other functions. MoonBit's naming convention requires that function names should not begin with uppercase letters (A-Z). Compare for constructors in the `enum` section below.

### Top-Level Functions

Functions can be defined as top-level or local. We can use the `fn` keyword to define a top-level function that sums three integers and returns the result, as follows:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start top-level functions
:end-before: end top-level functions
```

Note that the arguments and return value of top-level functions require **explicit** type annotations.

### Local Functions

Local functions can be named or anonymous. Type annotations can be omitted for local function definitions: they can be automatically inferred in most cases. For example:

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 1
:end-before: end local functions 1
```

There's also a form called **matrix function** that make use of [pattern matching](#pattern-matching):

```{literalinclude} /sources/language/src/functions/top.mbt
:language: moonbit
:start-after: start local functions 3
:end-before: end local functions 3
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

**Top-level** functions can declare labelled argument with the syntax `label~ : Type`. `label` will also serve as parameter name inside function body:

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

A conditional expression consists of a condition, a consequent, and an optional `else` clause or `else if` clause.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start conditional expressions 1
:end-before: end conditional expressions 1
```

The curly brackets around the consequent are required.

Note that a conditional expression always returns a value in MoonBit, and the return values of the consequent and the else clause must be of the same type. Here is an example:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start conditional expressions 3
:end-before: end conditional expressions 3
```

The `else` clause can only be omitted if the return value has type `Unit`.

### Match Expression

The `match` expression is similar to conditional expression, but it uses [pattern matching](#pattern-matching) to decide which consequent to evaluate and extracting variables at the same time.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start match 1
:end-before: end match 1
```

If a possible condition is omitted, the compiler will issue a warning, and the program will terminate if that case were reached.

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

#### Guard statement and is expression

The `let` statement can be used with [pattern matching](#pattern-matching). However, `let` statement can only handle one case. And using [is expression](#is-expression) with `guard` statement can solve this issue.

In the following example, `getProcessedText` assumes that the input `path` points to resources that are all plain text,
and it uses the `guard` statement to ensure this invariant while extracting the plain text resource.
Compared to using a `match` statement, the subsequent processing of `text` can have one less level of indentation.

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

`for .. in` loop also supports iterating through a sequence of integers, such as:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start for loop 10
:end-before: end for loop 10
```

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

```{warning}
Currently in `loop exprs { ... }`, `exprs` is nonempty list, while `for { ... }` is accepted for infinite loop.
```

### Labelled Continue/Break

When a loop is labelled, it can be referenced from a `break` or `continue` from
within a nested loop. For example:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start loop label
:end-before: end loop label
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

## Custom Data Types

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

If there's no other struct that has the same fields, it's redundant to add the struct's name when constructing it:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:dedent:
:start-after: start struct 5
:end-before: end struct 5
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

Unlike all other kinds of type declaration above, type alias does not define a new type,
it is merely a type macro that behaves exactly the same as its definition.
So for example one cannot define new methods or implement traits for a type alias.

```{tip}
Type alias can be used to perform incremental code refactor.

For example, if you want to move a type `T` from `@pkgA` to `@pkgB`,
you can leave a type alias `typealias T = @pkgB.T` in `@pkgA`, and **incrementally** port uses of `@pkgA.T` to `@pkgB.T`.
The type alias can be removed after all uses of `@pkgA.T` is migrated to `@pkgB.T`.
```

### Local types

Moonbit supports declaring structs/enums/newtypes at the top of a toplevel
function, which are only visible within the current toplevel function. These
local types can use the generic parameters of the toplevel function but cannot
introduce additional generic parameters themselves. Local types can derive
methods using derive, but no additional methods can be defined manually. For 
example:

```{literalinclude} /sources/language/src/data/top.mbt
:language: moonbit
:start-after: start local-type 1
:end-before: end local-type 1
```

Currently, local types do not support being declared as error types. 

## Pattern Matching

Pattern matching allows us to match on specific pattern and bind data from data structures.

### Simple Patterns

We can pattern match expressions against

- literals, such as boolean values, numbers, chars, strings, etc
- constants
- structs
- enums
- arrays
- maps
- JSONs

and so on. We can define identifiers to bind the matched values so that they can be used later.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start simple pattern 1
:end-before: end simple pattern 1
```

We can use `_` as wildcards for the values we don't care about, and use `..` to ignore remaining fields of struct or enum, or array (see [array pattern](#array-pattern)).

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start simple pattern 2
:end-before: end simple pattern 2
```

We can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 3
:end-before: end pattern 3
```

### Array Pattern

For `Array`, `FixedArray` and `ArrayView`, MoonBit allows using array pattern.

Array pattern have the following forms:

- `[]` : matching for an empty data structure
- `[pa, pb, pc]` : matching for known number of elements, 3 in this example
- `[pa, ..]` : matching for known number of elements, followed by unknown number of elements
- `[.., pa]` : matching for known number of elements, preceded by unknown number of elements

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:start-after: start pattern 2
:end-before: end pattern 2
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

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V` (see [method and trait](./methods.md)).
- Currently, the key part of map pattern must be a literal or constant
- Map patterns are always open: the unmatched keys are silently ignored, and `..` needs to be added to identify this nature
- Map pattern will be compiled to efficient code: every key will be fetched at most once

### Json Pattern

When the matched value has type `Json`, literal patterns can be used directly, together with constructors:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 6
:end-before: end pattern 6
```

## Generics

Generics are supported in top-level function and data type definitions. Type parameters can be introduced within square brackets. We can rewrite the aforementioned data type `List` to add a type parameter `T` to obtain a generic version of lists. We can then define generic functions over lists like `map` and `reduce`.

```{literalinclude} /sources/language/src/generics/top.mbt
:language: moonbit
```

## Special Syntax

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

### Is Expression

The `is` expression tests whether a value conforms to a specific pattern. It
returns a `Bool` value and can be used anywhere a boolean value is expected,
for example:

```{literalinclude} /sources/language/src/is/top.mbt
:language: moonbit
:dedent:
:start-after: start is 1
:end-before: end is 1
```

Pattern binders introduced by `is` expressions can be used in the following
contexts:

1. In boolean AND expressions (`&&`):
   binders introduced in the left-hand expression can be used in the right-hand
   expression

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 2
   :end-before: end is 2
   ```

2. In the first branch of `if` expression: if the condition is a sequence of
   boolean expressions `e1 && e2 && ...`, the binders introduced by the `is`
   expression can be used in the branch where the condition evaluates to `true`.

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 3
   :end-before: end is 3
   ```

3. In the following statements of a `guard` condition:

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 4
   :end-before: end is 4
   ```

4. In the body of a `while` loop:

   ```{literalinclude} /sources/language/src/is/top.mbt
   :language: moonbit
   :dedent:
   :start-after: start is 5
   :end-before: end is 5
   ```

### TODO syntax

The `todo` syntax (`...`) is a special construct used to mark sections of code that are not yet implemented or are placeholders for future functionality. For example:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start todo 1
:end-before: end todo 1
```
