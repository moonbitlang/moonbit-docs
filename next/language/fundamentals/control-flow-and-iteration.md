<span id="control-structures"></span>

# Control Flow and Iteration

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

The `while` loop also supports an optional `nobreak` clause. When the loop condition becomes false, the `nobreak` clause will be executed, and then the loop will end.

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

When there is an `nobreak` clause, the `while` loop can also return a value. The return value is the evaluation result of the `nobreak` clause. In this case, if you use `break` to exit the loop, you need to provide a return value after `break`, which should be of the same type as the return value of the `nobreak` clause.

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

The `for` loop also supports `continue`, `break`, and `nobreak` clauses. Like the `while` loop, the `for` loop can also return a value using the `break` and `nobreak` clauses.

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

## Range expression in `for .. in` loop

`for .. in` loops can also be used with range expressions for iterating over a number range:

```{literalinclude} /sources/language/src/controls/top.mbt
:language: moonbit
:start-after: start for loop 9
:end-before: end for loop 9
:prepend: "fn main {"
:append: "}"
```

```{literalinclude} /sources/language/src/controls/__snapshot__/for_loop_9
:caption: Output
```

There are four kinds of range expressions available in `for .. in` loop:

- `a..<b`: iterate from `a` to `b` in increasing order, excluding `b`
- `a..<=b`: iterate from `a` to `b` in increasing order, including `b`
- `a>..b`: iterate from `a` to `b` in decreasing order, excluding `a`
- `a>=..b`: iterate from `a` to `b` in decreasing  order, including `a`

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

## Iterator

An iterator is an object that traverse through a sequence while providing access
to its elements. Traditional OO languages like Java's `Iterator<T>` use `next()`
`hasNext()` to step through the iteration process, whereas functional languages
(JavaScript's `forEach`, Lisp's `mapcar`) provides a high-order function which
takes an operation and a sequence then consumes the sequence with that operation
being applied to the sequence. The former is called _external iterator_ (visible
to user) and the latter is called _internal iterator_ (invisible to user).

The built-in type `Iter[T]` is MoonBit's external iterator implementation. It
exposes `next()` to pull the next value: it returns `Some(value)` and advances
the iterator, or `None` when the iteration is finished.
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

Methods like `filter` and `map` are very common on a sequence object e.g. Array.
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

Iterators are single-pass: once you call `next()` or consume them with methods
like `each`, `fold`, or `collect`, their internal state advances and cannot be
reset. If you need to traverse the sequence again, request a new `Iter` from
the source.
