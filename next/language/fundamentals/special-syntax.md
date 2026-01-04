# Special Syntax

## Pipelines

MoonBit provides a convenient pipe syntax `x |> f(y)`, which can be used to chain regular function calls:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 4
:end-before: end operator 4
```

The MoonBit code follows the *data-first* style, meaning the function places its "subject" as the first argument. 
Thus, the pipe operator inserts the left-hand side value into the first argument of the right-hand side function call by default. 
For example, `x |> f(y)` is equivalent to `f(x, y)`.

You can use the `_` operator to insert `x` into any argument of the function `f`, such as `x |> f(y, _)`, which is equivalent to `f(y, x)`. Labeled arguments are also supported.


## Cascade Operator

The cascade operator `..` is used to perform a series of mutable operations on
the same value consecutively. The syntax is as follows:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start operator 5
:end-before: end operator 5
```

- `x..f()..g()` is equivalent to `{ x.f(); x.g(); }`.
- `x..f().g()` is equivalent to `{ x.f(); x.g(); }`.


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

## is Expression

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

Note that `is` expression can only take a simple pattern. If you need to use
`as` to bind the pattern to a variable, you have to add parentheses. For
example:
```{literalinclude} /sources/language/src/is/top.mbt
:language: moonbit
:dedent:
:start-after: start is 6
:end-before: end is 6
```

## Spread Operator

MoonBit provides a spread operator to expand a sequence of elements when
constructing `Array`, `String`, and `Bytes` using the array literal syntax. To
expand such a sequence, it needs to be prefixed with `..`, and it must have
`iter()` method that yields the corresponding type of element.

For example, we can use the spread operator to construct an array:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start spread 1
:end-before: end spread 1
```

Similarly, we can use the spread operator to construct a string:

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start spread 2
:end-before: end spread 2
```

The last example shows how the spread operator can be used to construct a bytes
sequence.

```{literalinclude} /sources/language/src/operator/top.mbt
:language: moonbit
:dedent:
:start-after: start spread 3
:end-before: end spread 3
```


## TODO syntax

The `todo` syntax (`...`) is a special construct used to mark sections of code that are not yet implemented or are placeholders for future functionality. For example:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start todo 1
:end-before: end todo 1
```
