# Writing Tests

Tests are important for improving quality and maintainability of a program. They verify the behavior of a program and also serves as a specification to avoid regressions over time.

MoonBit comes with test support to make the writing easier and simpler.

## Test Blocks

MoonBit provides the test code block for writing inline test cases. For example:

```moonbit
test "test_name" {
  assert_eq(1 + 1, 2)
  assert_eq(2 + 2, 4)
  debug_inspect([1, 2, 3], content="[1, 2, 3]")
}
```

A test code block is essentially a function with type
`() -> Unit raise Error`: it returns `Unit` and may raise an
[`Error`](https://docs.moonbitlang.com/en/latest/language/error-handling.html#error-types). It is called during the
execution of `moon test` and outputs a test report through the build system.
The `assert_eq` function is from the standard library; if the assertion fails,
it prints an error message and terminates the test. The string `"test_name"`
is used to identify the test case and is optional.

Tests started by `moon test` use the module root as their current working
directory. Resolve relative paths used by tests from the module root, rather
than from the package directory or the directory containing the test file.

If a test name starts with `"panic"`, it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```moonbit
test "panic_test" {
  let _ : Int32 = Option::None.unwrap()
}
```

## Snapshot Tests

Writing tests can be tedious when specifying the expected values. Thus, MoonBit provides three kinds of snapshot tests.
All of which can be inserted or updated automatically using `moon test --update`.

### Snapshotting `Show`

We can use `inspect(x, content="x")` to inspect anything that implements `Show` trait.
As we mentioned before, `Show` is a builtin trait that can be derived, providing `to_string` that will print the content of the data structures.
The labelled argument `content` can be omitted as `moon test --update` will insert it for you:

```moonbit
struct X {
  x : Int32
} derive(Debug)

pub extend X with Debug::{to_repr}

test "show snapshot test" {
  debug_inspect({ x: 10 }, content="{ x: 10 }")
}
```

### Snapshotting `JSON`

The problem with the derived `Show` trait is that it does not perform pretty printing, resulting in extremely long output.

The solution is to use `@json.inspect(x, content=x)`. The benefit is that the resulting content is a JSON structure, which can be more readable after being formatted.

```moonbit
enum Rec {
  End
  Really_long_name_that_is_difficult_to_read(Rec)
} derive(Debug, ToJson)

pub extend Rec with Debug::{to_repr}

pub extend Rec with ToJson::{to_json}

test "json snapshot test" {
  let r = Really_long_name_that_is_difficult_to_read(
    Really_long_name_that_is_difficult_to_read(
      Really_long_name_that_is_difficult_to_read(End),
    ),
  )
  debug_inspect(
    r,
    content="Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(End)))",
  )
  json_inspect(r, content=[
    "Really_long_name_that_is_difficult_to_read",
    [
      "Really_long_name_that_is_difficult_to_read",
      ["Really_long_name_that_is_difficult_to_read", "End"],
    ],
  ])
}
```

One can also implement a custom `ToJson` to keep only the essential information.

### Snapshotting Anything

Still, sometimes we want to not only record one data structure but the output of a whole process.

A full snapshot test can be used to record anything using `@test.T::write` and `@test.T::writeln`:

```moonbit
test "record anything" (t : @test.Test) {
  t.write("Hello, world!")
  t.writeln(" And hello, MoonBit!")
  t.snapshot(filename="record_anything.txt")
}
```

This will create a file under `__snapshot__` of that package with the given filename:

```none
Hello, world! And hello, MoonBit!
```

This can also be used for applications to test the generated output, whether it were creating an image, a video or some custom data.

Please note that `@test.T::snapshot` should be used at the end of a test block, as it always raises exception.

## Property-Based Tests

Example-based tests check particular inputs. Property-based tests describe a
relationship that should hold for many generated inputs. Use the standard
library's `quickcheck` package inside an ordinary `test` block; no additional
module dependency is needed. For examples in a `_test.mbt` file, add this import
to `moon.pkg`:

```moonbit
import {
  "moonbitlang/core/quickcheck",
} for "test"
```

### Checking a Property

Adding zero should leave an integer unchanged:

```moonbit
test "adding zero preserves an integer" {
  @quickcheck.check((x : Int32) => x + 0 == x, count=100, seed=2026)
}
```

Run this test with `moon test`. `check` generates inputs and calls the property
for each one. Returning `true` accepts a case; returning `false` or raising an
error causes `check` to report a failure. Here, `count` requests 100 cases and
`seed` makes the run repeatable. Generated `Int32` values are not limited to
small numbers: they can include values near the limits of the type.

The input type must implement `Arbitrary` to generate values, `Shrink` to
simplify failing inputs, and `Debug` to display them. These implementations are
provided for common types, including `Int32`. Keep properties deterministic
and avoid mutating their inputs.

### Understanding a Counterexample

What about adding one? `x + 1 > x` holds for mathematical integers, but does it
hold for `Int32`? Small examples such as 0, 1, and 100 would all pass. The
following example uses `report` to look for a counterexample. It returns a
result instead of raising a test failure, so we can record the failure report
in a snapshot while keeping the demonstration itself a passing test:

```moonbit
test "adding one does not always increase an integer" {
  let report = @quickcheck.report(
    (x : Int32) => x + 1 > x,
    count=100,
    seed=2026,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=2147483647,
      #|  tests=18,
      #|  size=17,
      #|  shrinks=0,
      #|  shrink_attempts=31,
      #|)
    ),
  )
}
```

`Falsified` means the property returned `false`. The counterexample is
`2147483647`, the largest `Int32`. Adding one overflows and wraps to
`-2147483648`, so the result is smaller, not larger. This is a mistaken
assumption about fixed-width arithmetic, not a bug in addition.

QuickCheck also tries simpler inputs that still fail, a process called
shrinking. Here, `shrinks=0`: no smaller input preserves the failure, since
only the largest `Int32` fails this property. The optional `max_shrinks`
argument limits the number of candidates examined; shrinking does not in
general guarantee the smallest counterexample. Use `check`, rather than
`report`, when a false property should fail your test suite.

### Keeping a Regression Test

To reproduce a run, keep the seed, settings, property, and toolchain/library
version the same. Generated cases and shrink results can change between
versions. Once a counterexample reveals a bug or a mistaken expectation, keep
that concrete input in an example-based test with the correct expected behavior:

```moonbit
test "adding one at the Int32 boundary" {
  let x : Int32 = 2147483647
  assert_eq(x + 1, -2147483648)
  assert_eq(x.to_int64() + 1, 2147483648L)
}
```

The second assertion converts to `Int64` **before** adding one, which is wide
enough for this calculation. Converting the result after `Int32` addition
would be too late: the overflow would already have happened.

Keep both kinds of tests: the regression test always checks the discovered
case, while the property test can explore more inputs with other seeds and
settings. Passing generated cases is not a proof that a property holds for all
inputs.

For custom generators and more ways to choose useful properties, see
[Property-Based Testing in MoonBit](https://www.moonbitlang.com/blog/property-based-testing-moonbit).

## BlackBox Tests and WhiteBox Tests

When developing libraries, it is important to verify if the user can use it correctly. For example, one may forget to make a type or a function public. That's why MoonBit provides BlackBox tests, allowing developers to have a grasp of how others are feeling.

- A test that has access to all the members in a package is called a WhiteBox tests as we can see everything. Such tests can be defined inline or defined in a file whose name ends with `_wbtest.mbt`.
- A test that has access only to the public members in a package is called a BlackBox tests. Such tests need to be defined in a file whose name ends with `_test.mbt`.

The WhiteBox test files (`_wbtest.mbt`) imports the packages defined in the `import` and `wbtest-import` sections of the package configuration (`moon.pkg`, or legacy `moon.pkg.json`).

The BlackBox test files (`_test.mbt`) imports the current package and the packages defined in the `import` and `test-import` sections of the package configuration (`moon.pkg`, or legacy `moon.pkg.json`).
