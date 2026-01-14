# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`, `let`, `enum`, `struct` or `type`. The doc comments are written in markdown.

```moonbit
/// Return a new array with reversed elements.
fn[T] reverse(xs : Array[T]) -> Array[T] {
  ...
}
```

Markdown code blocks inside docstrings marked with `mbt check` are treated as
document tests. `moon check` and `moon test` will automatically check and run
these tests, so that examples in docstring are always up-to-date.
Wrap the snippet in `test { .. }` when you want a test block:

```moonbit
/// Increment an integer by one,
///
/// Example:
/// ```mbt check
/// test {
///   inspect(incr(41), content="42")
/// }
/// ```
pub fn incr(x : Int) -> Int {
  x + 1
}
```

Doc tests also apply to literate `.mbt.md` files. For a standalone file, run
`moon check README.mbt.md` and `moon test README.mbt.md`. Inside a project, use
the package-level `moon check` and `moon test` instead.

If you want to prevent a code snippet from being treated as a document test,
mark it with a language id other than `mbt check` on the markdown code block:

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
