# Comments and Documentation

## Comments

Use `//` for ordinary comments inside code:

```moonbit
// Explain why this branch exists.
let retries = 3
```

You will also often see `///|` at the start of top-level blocks. It is an
empty doc-comment line used to split top-level items explicitly. This matters
for documentation tooling today, and it also preserves clear top-level block
boundaries for future caching and other tooling purposes. In practice, `///|`
is useful in ordinary MoonBit code as well as in documentation sources.

## Doc Comments

Doc comments use `///` on each line immediately before a top-level item such as
`fn`, `let`, `enum`, `struct`, or `type`. Doc comments are written in
Markdown.

```moonbit
/// Return a new array with reversed elements.
fn[T] reverse(xs : Array[T]) -> Array[T] {
  ...
}
```

Markdown code blocks inside doc comments marked with `mbt check` are treated as
document tests. `moon check` and `moon test` will automatically check and run
these tests, so that examples in doc comments are always up-to-date.
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
