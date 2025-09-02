# Error handling

Error handling has always been at core of our language design. In the following
we'll be explaining how error handling is done in MoonBit. We assume you have
some prior knowledge of MoonBit, if not, please checkout
[A tour of MoonBit](../tutorial/tour.md).

## Error Types

In MoonBit, all the error values can be represented by the `Error` type, a
generalized error type.

However, an `Error` cannot be constructed directly. A concrete error type must
be defined, in the following forms:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 1
:end-before: end error 1
```

The error types can be promoted to the `Error` type automatically, and pattern
matched back:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start custom error conversion
:end-before: end custom error conversion
```

Since the type `Error` can include multiple error types, pattern matching on the
`Error` type must use the wildcard `_` to match all error types. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 6
:end-before: end error 6
```

The `Error` is meant to be used where no concrete error type is needed, or a
catch-all for all kinds of sub-errors is needed.

### Failure

A builtin error type is `Failure`.

There's a handly `fail` function, which is merely a constructor with a
pre-defined output template for showing both the error and the source location.
In practice, `fail` is always preferred over `Failure`.

<!-- MANUAL CHECK -->

```{code-block} moonbit
:class: top-level
#callsite(autofill(loc))
pub fn[T] fail(msg : String, loc~ : SourceLoc) -> T raise Failure {
  raise Failure("FAILED: \{loc} \{msg}")
}
```

## Throwing Errors

The keyword `raise` is used to interrupt the function execution and return an
error.

The type declaration of a function can use `raise` with an Error type to
indicate that the function might raise an error during an execution. For
example, the following function `div` might return an error of type `DivError`:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 2
:end-before: end error 2
```

The `Error` can be used when the concrete error type is not important. For
convenience, you can omit the error type after the `raise` to indicate that the
`Error` type is used. For example, the following function signatures are
equivalent:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 3
:end-before: end error 3
```

For functions that are generic in the error type, you can use the `Error` bound
to do that. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 5
:end-before: end error 5
```

For functions that do not raise an error, you can add `noraise` in the
signature. For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start noraise
:end-before: end noraise
```

### Error Polymorphism

It happens when a higher order function accepts another function as parameter.
The function as parameter may or may not throw error, which in turn affects the
behavior of this function.

A notable example is `map` of `Array`:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error polymorphism
:end-before: end error polymorphism
```

However, writing so would make the `map` function constantly having the
possibility of throwing errors, which is not the case.

Thus, the error polymorphism is introduced. You may use `raise?` to signify that
an error may or may not be throw.

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error polymorphism 2
:end-before: end error polymorphism 2
```

The signature of the `map_with_polymorphism` will be determined by the actual
parameter.

## Handling Errors

Applying the function normally will rethrow the error directly in case of an
error. For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 7
:end-before: end error 7
```

However, you may want to handle the errors.

### Try ... Catch

You can use `try` and `catch` to catch and handle errors, for example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
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
block will not be executed and the `noraise` block will be executed instead.

The `noraise` block can be omitted if no action is needed when no error is
caught. For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 10
:end-before: end error 10
```

When the body of `try` is a simple expression, the curly braces, and even the
`try` keyword can be omitted. For example:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 11
:end-before: end error 11
```

### Transforming to Result

You can also catch the potential error and transform into a first-class value of
the [`Result`](/language/fundamentals.md#option-and-result) type, by using
`try?` before an expression that may throw error:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 8
:end-before: end error 8
```

### Panic on Errors

You can also panic directly when an unexpected error occurs:

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:start-after: start error 14
:end-before: end error 14
```

### Error Inference

Within a `try` block, several different kinds of errors can be raised. When that
happens, the compiler will use the type `Error` as the common error type.
Accordingly, the handler must use the wildcard `_` to make sure all errors are
caught, and `e => raise e` to reraise the other errors. For example,

```{literalinclude} /sources/language/src/error/top.mbt
:language: moonbit
:dedent:
:start-after: start error 13
:end-before: end error 13
```
