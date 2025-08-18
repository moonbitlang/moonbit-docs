# Writing Tests

Tests are important for improving quality and maintainability of a program. They verify the behavior of a program and also serves as a specification to avoid regressions over time.

MoonBit comes with test support to make the writing easier and simpler.

## Test Blocks

MoonBit provides the test code block for writing inline test cases. For example:

```moonbit
test "test_name" {
  assert_eq(1 + 1, 2)
  assert_eq(2 + 2, 4)
  inspect([1, 2, 3], content="[1, 2, 3]")
}
```

A test code block is essentially a function that returns a `Unit` but may throws an [`Error`](error-handling.md#error-types), or `Unit!Error` as one would see in its signature at the position of return type. It is called during the execution of `moon test` and outputs a test report through the build system. The `assert_eq` function is from the standard library; if the assertion fails, it prints an error message and terminates the test. The string `"test_name"` is used to identify the test case and is optional.

If a test name starts with `"panic"`, it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```moonbit
test "panic_test" {
  let _ : Int = Option::None.unwrap()

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
  x : Int
} derive(Show)

test "show snapshot test" {
  inspect({ x: 10 }, content="{x: 10}")
}
```

### Snapshotting `JSON`

The problem with the derived `Show` trait is that it does not perform pretty printing, resulting in extremely long output.

The solution is to use `@json.inspect(x, content=x)`. The benefit is that the resulting content is a JSON structure, which can be more readable after being formatted.

```moonbit
enum Rec {
  End
  Really_long_name_that_is_difficult_to_read(Rec)
} derive(Show, ToJson(style="flat"))

test "json snapshot test" {
  let r = Really_long_name_that_is_difficult_to_read(
    Really_long_name_that_is_difficult_to_read(
      Really_long_name_that_is_difficult_to_read(End),
    ),
  )
  inspect(
    r,
    content="Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(Really_long_name_that_is_difficult_to_read(End)))",
  )
  @json.inspect(r, content=[
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
test "record anything" (t : @test.T) {
  t.write("Hello, world!")
  t.writeln(" And hello, MoonBit!")
  t.snapshot(filename="record_anything.txt")
}
```

This will create a file under `__snapshot__` of that package with the given filename:

```default
Hello, world! And hello, MoonBit!
```

This can also be used for applications to test the generated output, whether it were creating an image, a video or some custom data.

Please note that `@test.T::snapshot` should be used at the end of a test block, as it always raises exception.

## BlackBox Tests and WhiteBox Tests

When developing libraries, it is important to verify if the user can use it correctly. For example, one may forget to make a type or a function public. That's why MoonBit provides BlackBox tests, allowing developers to have a grasp of how others are feeling.

- A test that has access to all the members in a package is called a WhiteBox tests as we can see everything. Such tests can be defined inline or defined in a file whose name ends with `_wbtest.mbt`.
- A test that has access only to the public members in a package is called a BlackBox tests. Such tests need to be defined in a file whose name ends with `_test.mbt`.

The WhiteBox test files (`_wbtest.mbt`) imports the packages defined in the `import` and `wbtest-import` sections of the package configuration (`moon.pkg.json`).

The BlackBox test files (`_test.mbt`) imports the current package and the packages defined in the `import` and `test-import` sections of the package configuration (`moon.pkg.json`).
