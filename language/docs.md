# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`, `let`, `enum`, `struct` or `type`. The doc comments are written in markdown.

```moonbit
/// Return a new array with reversed elements.
fn[T] reverse(xs : Array[T]) -> Array[T] {
  ...
}
```

Markdown code block inside docstring will be considered document test,
`moon check` and `moon test` will automatically check and run these tests, so that examples in docstring are always up-to-date.
MoonBit will automatically wrap a test block around document test,
so there is no need to wrap `test { .. }` around document test:

```moonbit
/// Increment an integer by one,
///
/// Example:
/// ```
/// inspect(incr(41), content="42")
/// ```
pub fn incr(x : Int) -> Int {
  x + 1
}
```

If you want to prevent a code snippet from being treated as document test,
mark it with a language id other than `mbt` on the markdown code block:

```moonbit
/// `c_incr(x)` is the same as the following C code:
/// ```c
/// x++
/// ```
pub fn c_incr(x : Ref[Int]) -> Int {
  let old = x.val
  x.val += 1
  old
}
```

Currently, document tests are always [blackbox tests](tests.md#blackbox-tests-and-whitebox-tests).
So private definitions cannot have document test.
