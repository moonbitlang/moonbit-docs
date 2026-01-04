# Control Structures

## Conditional Expressions

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

## Match Expression

The `match` expression is similar to conditional expression, but it uses [pattern matching](pattern-matching.md) to decide which consequent to evaluate and extracting variables at the same time.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start match 1
:end-before: end match 1
```

If a possible condition is omitted, the compiler will issue a warning, and the program will terminate if that case were reached.

## Guard Statement

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

### Guard statement and is expression

The `let` statement can be used with [pattern matching](pattern-matching.md). However, `let` statement can only handle one case. And using [is expression](special-syntax.md#is-expression) with `guard` statement can solve this issue.

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

## While loop

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

## For Loop

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

## `for .. in` loop

MoonBit supports traversing elements of different data structures and sequences via the `for .. in` loop syntax:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:dedent:
:start-after: start for loop 5
:end-before: end for loop 5
```

`for .. in` loop is translated to the use of `Iter` in MoonBit's standard library. Any type with a method `.iter() : Iter[T]` can be traversed using `for .. in`.
For more information of the `Iter` type, see [Iterator](iterator.md) below.

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

## Functional loop

Functional loop is a powerful feature in MoonBit that enables you to write loops in a functional style.

A functional loop consumes an argument and returns a value. It is defined using the `loop` keyword, followed by its argument and the loop body. The loop body is a sequence of clauses, each of which consists of a pattern and an expression. The clause whose pattern matches the input will be executed, and the loop will return the value of the expression. If no pattern matches, the loop will panic. Use the `continue` keyword with arguments to start the next iteration of the loop. Use the `break` keyword with an argument to return a value from the loop. The `break` keyword can be omitted if the value is the last expression in the loop body.

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start functional loop
:end-before: end functional loop
```

```{hint}
Use `while true { ... }` or `for { ... }` for infinite loop.
```

## Labelled Continue/Break

When a loop is labelled, it can be referenced from a `break` or `continue` from
within a nested loop. For example:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start loop label
:end-before: end loop label
```

## `defer` expression

`defer` expression can be used to perform reliable resource cleanup.
The syntax for `defer` is as follows:

```moonbit
defer <expr>
<body>
```

Whenever the program leaves `body`, `expr` will be executed.
For example, the following program:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start defer 1
:end-before: end defer 1
```

will first print `do things with the resource`, and then `perform resource cleanup`.
`defer` expression will always get executed no matter how its body exits.
It can handle [error](/language/error-handling.md),
as well as control flow constructs including `return`, `break` and `continue`.

Consecutive `defer` will be executed in reverse order, for example, the following:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start defer 2
:end-before: end defer 2
```

will output first `do things`, then `second defer`, and finally `first defer`.

`return`, `break` and `continue` are disallowed in the right hand side of `defer`.
Currently, raising error or calling `async` function is also disallowed in the right hand side of `defer`.
