# Testing and Benchmarking

Tests are important for improving quality and maintainability of a program. They verify the behavior of a program and also serves as a specification to avoid regressions over time.

MoonBit comes with test support to make the writing easier and simpler.

## Test Blocks

MoonBit provides the test code block for writing inline test cases. For example:

```{literalinclude} /sources/language/src/testing/top.mbt
:language: moonbit
:start-after: start test 1
:end-before: end test 1
```

A test code block is essentially a function that returns a `Unit` but may throws an [`Error`](/language/error-handling.md#error-types), or `Unit!Error` as one would see in its signature at the position of return type. It is called during the execution of `moon test` and outputs a test report through the build system. The `assert_eq` function is from the standard library; if the assertion fails, it prints an error message and terminates the test. The string `"test_name"` is used to identify the test case and is optional. 

If a test name starts with `"panic"`, it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```{literalinclude} /sources/language/src/testing/top.mbt
:language: moonbit
:start-after: start test 2
:end-before: end test 2
```

## Snapshot Tests

Writing tests can be tedious when specifying the expected values. Thus, MoonBit provides three kinds of snapshot tests.
All of which can be inserted or updated automatically using `moon test --update`.

### Snapshotting `Show`

We can use `inspect(x, content="x")` to inspect anything that implements `Show` trait. 
As we mentioned before, `Show` is a builtin trait that can be derived, providing `to_string` that will print the content of the data structures. 
The labelled argument `content` can be omitted as `moon test --update` will insert it for you:

```{literalinclude} /sources/language/src/testing/top.mbt
:language: moonbit
:start-after: start snapshot test 1
:end-before: end snapshot test 1
```

### Snapshotting `JSON`

The problem with the derived `Show` trait is that it does not perform pretty printing, resulting in extremely long output.

The solution is to use `@json.inspect(x, content=x)`. The benefit is that the resulting content is a JSON structure, which can be more readable after being formatted.

```{literalinclude} /sources/language/src/testing/top.mbt
:language: moonbit
:start-after: start snapshot test 2
:end-before: end snapshot test 2
```

One can also implement a custom `ToJson` to keep only the essential information.

### Snapshotting Anything

Still, sometimes we want to not only record one data structure but the output of a whole process.

A full snapshot test can be used to record anything using `@test.T::write` and `@test.T::writeln`:

```{literalinclude} /sources/language/src/testing/top.mbt
:language: moonbit
:start-after: start snapshot test 3
:end-before: end snapshot test 3
```

This will create a file under `__snapshot__` of that package with the given filename:

```{literalinclude} /sources/language/src/testing/__snapshot__/record_anything.txt
```

This can also be used for applications to test the generated output, whether it were creating an image, a video or some custom data.

Please note that `@test.T::snapshot` should be used at the end of a test block, as it always raises exception.

## BlackBox Tests and WhiteBox Tests

When developing libraries, it is important to verify if the user can use it correctly. For example, one may forget to make a type or a function public. That's why MoonBit provides BlackBox tests, allowing developers to have a grasp of how others are feeling.

- A test that has access to all the members in a package is called a WhiteBox tests as we can see everything. Such tests can be defined inline or defined in a file whose name ends with `_wbtest.mbt`.

- A test that has access only to the public members in a package is called a BlackBox tests. Such tests need to be defined in a file whose name ends with `_test.mbt`.

The WhiteBox test files (`_wbtest.mbt`) imports the packages defined in the `import` and `wbtest-import` sections of the package configuration (`moon.pkg`, or legacy `moon.pkg.json`).

The BlackBox test files (`_test.mbt`) imports the current package and the packages defined in the `import` and `test-import` sections of the package configuration (`moon.pkg`, or legacy `moon.pkg.json`).

## Writing Benchmarks

Benchmarks are a way to measure the performance of your code. They can be used to compare different implementations or to track performance changes over time.

### Benchmarking with Test Blocks

The most simple way to benchmark a function is to use a test block with a
`@bench.T` argument. It has a method `@bench.T::bench` that takes a function of type
`() -> Unit` and run it with a suitable number of iterations.
The measurements and statistical analysis will be conducted and passed to `moon`,
where they will be displayed in the console output.

```{literalinclude} /sources/language/src/benchmark/top.mbt
:language: moonbit
:start-after: start bench 1
:end-before: end bench 1
```

The output is as follows:

```
time (mean ± σ)         range (min … max)
  21.67 µs ±   0.54 µs    21.28 µs …  23.14 µs  in 10 ×   4619 runs
```

The function is executed `10 × 4619` times.
The second number is automatically detected by benchmark utilities, which increase the number of iterations until the measurement time is long enough for accurate timing.
The first number can be adjusted by passing a named parameter `count` to the `@bench.T::bench` argument.

```{literalinclude} /sources/language/src/benchmark/top.mbt
:language: moonbit
:start-after: start bench 2
:end-before: end bench 2
```

`@bench.T::keep` is an important auxiliary function that prevents your calculation from being optimized away and skipped entirely.
If you are benchmarking a pure function, make sure to use this function to avoid potential optimizations.
However, there is still a possibility that the compiler might pre-calculate and replace the calculation with a constant.

### Batch Benchmarking

A common scenario of benchmarking is to compare two or more implementations of the same function.
In this case, you may want to bench them in a batch within a block for easy comparison.
The `name` parameter of the `@bench.T::bench` method can be used to identify the benchmark.

```{literalinclude} /sources/language/src/benchmark/top.mbt
:language: moonbit
:start-after: start bench 3
:end-before: end bench 3
```

Now you can evaluate which one is faster by looking at the output:

```
name      time (mean ± σ)         range (min … max)
naive_fib   21.01 µs ±   0.21 µs    20.76 µs …  21.32 µs  in 10 ×   4632 runs
fast_fib     0.02 µs ±   0.00 µs     0.02 µs …   0.02 µs  in 10 × 100000 runs
```

### Raw Benchmark Statistics

Sometimes users may want to obtain raw benchmark statistics for further analysis.
There is a function `@bench.single_bench` that returns an abstract `Summary` type, which can be serialized into JSON format. The stability of the `Summary` type is not guaranteed to be stable.

In this case, users must ensure that the calculation is not optimized away.
There is no `keep` function available as a standalone function; it is a method of `@bench.T`.

```{literalinclude} /sources/language/src/benchmark/top.mbt
:language: moonbit
:start-after: start bench 4
:end-before: end bench 4
```

The output may look like this:

```json
6765
{
    "name": "fib",
    "sum": 217.22039973878972,
    "min": 21.62009230518067,
    "max": 21.87286402916848,
    "mean": 21.72203997387897,
    "median": 21.70412048323901,
    "var": 0.007197724461032505,
    "std_dev": 0.08483940394081341,
    "std_dev_pct": 0.39056830777787843,
    "median_abs_dev": 0.08189815918589166,
    "median_abs_dev_pct": 0.3773392211360855,
    "quartiles": [
        21.669052078798433,
        21.70412048323901,
        21.76141434479756
    ],
    "iqr": 0.09236226599912811,
    "batch_size": 4594,
    "runs": 10
}
```

Time units are in microseconds.
