# Error handling

Error handling has always been at core of our language design. In the following
we'll be explaining how error handling is done in MoonBit. We assume
you have some prior knowledge of MoonBit, if not, please checkout [A tour of MoonBit](../tutorial/tour.md).

## Error types

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

## The Default Error Type

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

## Handling Errors

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

## Error Inference

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

## Example: Division by Zero

We'll write a small example to demonstrate the basics of MoonBit's error
handling system. Consider the following `div` function which'll raise an error
on division by zero:

```moonbit
type! DivisionByZeroError String
fn div(x : Int, y : Int) -> Int!DivisionByZeroError {
  if y == 0 {
    raise DivisionByZeroError("division by zero")
  }
  x / y
}
```

In before, we would typically use `type` to define a wrapper type which wraps
around some existing foreign type. Here however, we append `type` with `!` to
define a error type `DivisionByZeroError` which wraps around `String`.

> `type! E S` construct a error type `E` from `S`

Just like `type`, `type!` may have a payload like the above `DivisionByZeroError`, or may not, or may even have multiple constructors like a normal `enum`:

```moonbit
type! ConnectionError {
  BrokenPipe(Int,String)
  ConnectionReset
  ConnectionAbort
  ConnectionRefused
}
```

To utilize `DivisionByZeroError` type, we would usually define a function which may raise
error by denoting its return type like `T ! E` in the signature, with `T` being
the actual return type and `E` being the error type. In this case, it's
`Int!DivisionByZeroError`. The error can be thrown using
`raise e` where `e` is an instance of `E` which can be constructed using the
default constructor of `S`.

Any instance of an error is a second class object. Meaning it may only appear in
the return value. And if it does appear, the function signature has to be
adjusted to match with the return type.

The `test` block in MoonBit may also be seen as a function, with a return type
of `Unit!Error`.

## Calling an error-able function

an error-able function is usually called in 2 manners: `f!(...)` and `f?(...)`.

### As-is calling

`f!(...)` calls the function directly. The possible error must be dealt in the
function that calls `f`. We can either re-raising it without actually dealing
with the error:

```moonbit -E0001 -E0002
// We have to match the error type of `div2` with `div`
fn div2(x : Int, y : Int) -> Int!DivisionByZeroError {
  div!(x,y)
}
```

or use `try...catch` block like in many other languages:

```moonbit
fn div3(x : Int, y : Int) -> Unit {
  try {
    div!(x, y)
  } catch { // `catch` and `except` works the same.
    DivisionByZeroError(e) => println("inf: \{e}")
  } else {
    v => println(v)
  }
}
```

The `catch...` clause has similar semantics like pattern matching. We can unwrap
the error to retrieve the underlying `String` and print it. Additionally,
there's an `else` clause to handle the value of `try...` block.

```moonbit
fn test_try() -> Result[Int, Error] {
  // compiler can figure out the type of a local error-able function.
  fn f() -> _!_ {
    raise Failure("err")
  }

  try Ok(f!()) { err => Err(err) }
}
```

Curly braces may be omitted if the body of try is a one-liner (expression). The
`catch` keyword can also be omitted as well. In the case where a `try` body would raise different errors,
the special `catch!` can be used to catch some of the errors, while re-raising other uncaught errors:

```moonbit
type! E1
type! E2
fn f1() -> Unit!E1 { raise E1 }
fn f2() -> Unit!E2 { raise E2 }
fn f() -> Unit! {
  try {
    f1!()
    f2!()
  } catch! {
    E1 => println("E1")
    // E2 gets re-raised.
  }
}
```

### Convert to Result

#### Extracting values

A object of type `Result` is a first class value in MoonBit. `Result` has 2 constructors: `Ok(...)` and `Err(...)` where the former accept a first class object and the latter accept a error object.

With `f?(...)`, the return type `T!E` is turned into `Result[T,E]`. We may use pattern matching to extract value from it:

```moonbit enclose
let res = div?(10, 0)
match res {
  Ok(x) => println(x)
  Err(DivisionByZeroError(e)) => println(e)
}
```

the `f?()` is basically a syntactic sugar for

```moonbit enclose
let res = try {
  Ok(div!(10, 0))
} catch {
  s => Err(s)
}
```

> Note the difference between `T?` and `f?(...)`: `T` is a type and `T?` is
> equivalent to `Option[T]` whereas `f?(...)` is a call to an error-able function
> `f`.

Besides pattern matching, `Result` provides some useful methods to deal with possible error:

```moonbit no-check
let res1: Result[Int, String] = Err("error")
let value = res1.or(0) // 0

let res2: Result[Int, String] = Ok(42)
let value = res2.unwrap() // 42
```

- `or` returns the value if the result is `Ok` or a default value if it is `Err`
- `unwrap` panics if the result is `Err` and return the value if it is `Ok`

#### Mapping values

```moonbit no-check
let res1: Result[Int, String] = Ok(42)
let new_result = res1.map(fn(x) { x + 1 }) // Ok(43)

let res2: Result[Int, String] = Err("error")
let new_result = res2.map_err(fn(x) { x + "!" }) // Err("error!")
```

- `map` applies a function to the value within, except it doesn't nothing if result is `Err`.
- `map_err` does the opposite.

Unlike some languages, MoonBit treats error-able and nullable value differently. Although one might treat them analogously, as an `Err` result contains no value, only the error, which is like `null`. MoonBit knows that.

- `to_option` converts a `Result` to `Option`.

```moonbit no-check
let res1: Result[Int, String] = Ok(42)
let option = res1.to_option() // Some(42)

let res2: Result[Int, String] = Err("error")
let option1 = res2.to_option() // None
```

## Built-in error type and functions

In MoonBit, `Error` is a generalized error type:

```moonbit no-check
// These signatures are equivalent. They all raise Error.
fn f() -> Unit! { .. }
fn f!() -> Unit { .. }
fn f() -> Unit!Error { .. }

fn test_error() -> Result[Int, Error] {
  fn f() -> _!_ {
    raise DivisionByZeroError("err")
  }

  try {
    Ok(f!())
  } catch {
    err => Err(err)
  }
}
```

Although the constructor `Err` expects a type of `Error`, we may
still pass an error of type `DivisionByZeroError` to it.

But `Error` can't be constructed directly. It's meant to be passed around, not used directly:

```moonbit
type! ArithmeticError

fn what_error_is_this(e : Error) -> Unit {
  match e {
    DivisionByZeroError(_) => println("DivisionByZeroError")
    ArithmeticError => println("ArithmeticError")
    ... => println("...")
    _ => println("Error")
  }
}
```

`Error` is typically used where concrete error type is not needed,
or simply act as a catch-all for all kinds of sub-errors.

As `Error` includes multiple error types, partial matching is not allowed here. We have to do exhaustive matching by providing a catch-all/wildcard case `_`.

We usually use the builtin `Failure` error type for a generalized error, and by
generalized we mean using it for trivial errors that doesn't need a new error type.

```moonbit
fn div_trivial(x : Int, y : Int) -> Int!Failure {
  if y == 0 {
    raise Failure("division by zero")
  }
  x / y
}
```

Besides using the constructor directly, the function `fail!` provides a
shorthand to construct a `Failure`. And if we take a look at the source code:

```moonbit
pub fn fail[T](msg : String, ~loc : SourceLoc = _) -> T!Failure {
  raise Failure("FAILED: \{loc} \{msg}")
}
```

We can see that `fail` is merely a constructor with a pre-defined output
template for showing both the error and the source location. In practice, `fail!`
is always preferred over `Failure`.

Other functions used to break control flow are `abort` and `panic`. They are equivalent. An `panic` at any place will manually crash the program at that place, and prints out stack trace.
