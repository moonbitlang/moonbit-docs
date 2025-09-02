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

```moonbit
suberror E1 Int // error type E1 has one constructor E1 with an Int payload

suberror E2 // error type E2 has one constructor E2 with no payload

suberror E3 { // error type E3 has three constructors like a normal enum type
  A
  B(Int, x~ : String)
  C(mut x~ : String, Char, y~ : Bool)
}
```

The error types can be promoted to the `Error` type automatically, and pattern
matched back:

```moonbit
suberror CustomError UInt

test {
  let e : Error = CustomError(42)
  guard e is CustomError(m)
  assert_eq(m, 42)
}
```

Since the type `Error` can include multiple error types, pattern matching on the
`Error` type must use the wildcard `_` to match all error types. For example,

```moonbit
fn f(e : Error) -> Unit {
  match e {
    E2 => println("E2")
    A => println("A")
    B(i, x~) => println("B(\{i}, \{x})")
    _ => println("unknown error")
  }
}
```

The `Error` is meant to be used where no concrete error type is needed, or a
catch-all for all kinds of sub-errors is needed.

### Failure

A builtin error type is `Failure`.

There's a handly `fail` function, which is merely a constructor with a
pre-defined output template for showing both the error and the source location.
In practice, `fail` is always preferred over `Failure`.

<!-- MANUAL CHECK -->
```moonbit
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

```moonbit
suberror DivError String

fn div(x : Int, y : Int) -> Int raise DivError {
  if y == 0 {
    raise DivError("division by zero")
  }
  x / y
}
```

The `Error` can be used when the concrete error type is not important. For
convenience, you can omit the error type after the `raise` to indicate that the
`Error` type is used. For example, the following function signatures are
equivalent:

```moonbit
fn f() -> Unit raise {
  ...
}

fn g() -> Unit raise Error {
  let h : () -> Unit raise = fn() raise { fail("fail") }
  ...
}
```

For functions that are generic in the error type, you can use the `Error` bound
to do that. For example,

```moonbit
// Result::unwrap_or_error
fn[T, E : Error] unwrap_or_error(result : Result[T, E]) -> T raise E {
  match result {
    Ok(x) => x
    Err(e) => raise e
  }
}
```

For functions that do not raise an error, you can add `noraise` in the
signature. For example:

```moonbit
fn add(a : Int, b : Int) -> Int noraise {
  a + b
}
```

### Error Polymorphism

It happens when a higher order function accepts another function as parameter.
The function as parameter may or may not throw error, which in turn affects the
behavior of this function.

A notable example is `map` of `Array`:

```moonbit
fn[T] map(array : Array[T], f : (T) -> T raise) -> Array[T] raise {
  let mut res = []
  for x in array {
    res.push(f(x))
  }
  res
}
```

However, writing so would make the `map` function constantly having the
possibility of throwing errors, which is not the case.

Thus, the error polymorphism is introduced. You may use `raise?` to signify that
an error may or may not be throw.

```moonbit
fn[T] map_with_polymorphism(
  array : Array[T],
  f : (T) -> T raise?
) -> Array[T] raise? {
  let mut res = []
  for x in array {
    res.push(f(x))
  }
  res
}

fn[T] map_without_error(array : Array[T], f : (T) -> T noraise) -> Array[T] noraise {
  map_with_polymorphism(array, f)
}

fn[T] map_with_error(array : Array[T], f : (T) -> T raise) -> Array[T] raise {
  map_with_polymorphism(array, f)
}
```

The signature of the `map_with_polymorphism` will be determined by the actual
parameter.

## Handling Errors

Applying the function normally will rethrow the error directly in case of an
error. For example:

```moonbit
fn div_reraise(x : Int, y : Int) -> Int raise DivError {
  div(x, y) // Rethrow the error if `div` raised an error
}
```

However, you may want to handle the errors.

### Try ... Catch

You can use `try` and `catch` to catch and handle errors, for example:

```moonbit
fn main {
  try div(42, 0) catch {
    DivError(s) => println(s)
  } noraise {
    v => println(v)
  }
}
```

```default
division by zero
```

Here, `try` is used to call a function that might throw an error, and `catch` is
used to match and handle the caught error. If no error is caught, the catch
block will not be executed and the `noraise` block will be executed instead.

The `noraise` block can be omitted if no action is needed when no error is
caught. For example:

```moonbit
try { println(div(42, 0)) } catch {
  _ => println("Error")
}
```

When the body of `try` is a simple expression, the curly braces, and even the
`try` keyword can be omitted. For example:

```moonbit
let a = div(42, 0) catch { _ => 0 }
println(a)
```

### Transforming to Result

You can also catch the potential error and transform into a first-class value of
the [`Result`](fundamentals.md#option-and-result) type, by using
`try?` before an expression that may throw error:

```moonbit
test {
  let res = try? (div(6, 0) * div(6, 3))
  inspect(
    res,
    content=(
      #|Err("division by zero")
    ),
  )
}
```

### Panic on Errors

You can also panic directly when an unexpected error occurs:

```moonbit
fn remainder(a : Int, b : Int) -> Int raise DivError {
  if b == 0 {
    raise DivError("division by zero")
  }
  let div = try! div(a, b)
  a - b * div
}
```

### Error Inference

Within a `try` block, several different kinds of errors can be raised. When that
happens, the compiler will use the type `Error` as the common error type.
Accordingly, the handler must use the wildcard `_` to make sure all errors are
caught, and `e => raise e` to reraise the other errors. For example,

```moonbit
fn f1() -> Unit raise E1 {
  ...
}

fn f2() -> Unit raise E2 {
  ...
}

try {
  f1()
  f2()
} catch {
  E1(_) => ...
  E2 => ...
  e => raise e
}
```
