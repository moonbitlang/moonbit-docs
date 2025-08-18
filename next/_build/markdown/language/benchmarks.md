# Writing Benchmarks

Benchmarks are a way to measure the performance of your code. They can be used to compare different implementations or to track performance changes over time.

## Benchmarking with Test Blocks

The most simple way to benchmark a function is to use a test block with a
`@bench.T` argument. It has a method `@bench.T::bench` that takes a function of type
`() -> Unit` and run it with a suitable number of iterations.
The measurements and statistical analysis will be conducted and passed to `moon`,
where they will be displayed in the console output.

```moonbit
fn fib(n : Int) -> Int {
  if n < 2 {
    return n
  }
  return fib(n - 1) + fib(n - 2)
}

test (b : @bench.T) {
  b.bench(fn() { b.keep(fib(20)) })
}
```

The output is as follows:

```default
time (mean ± σ)         range (min … max) 
  21.67 µs ±   0.54 µs    21.28 µs …  23.14 µs  in 10 ×   4619 runs
```

The function is executed `10 × 4619` times.
The second number is automatically detected by benchmark utilities, which increase the number of iterations until the measurement time is long enough for accurate timing.
The first number can be adjusted by passing a named parameter `count` to the `@bench.T::bench` argument.

```moonbit
test (b : @bench.T) {
  b.bench(fn() { b.keep(fib(20)) }, count=20)
}
```

`@bench.T::keep` is an important auxiliary function that prevents your calculation from being optimized away and skipped entirely.
If you are benchmarking a pure function, make sure to use this function to avoid potential optimizations.
However, there is still a possibility that the compiler might pre-calculate and replace the calculation with a constant.

## Batch Benchmarking

A common scenario of benchmarking is to compare two or more implementations of the same function.
In this case, you may want to bench them in a batch within a block for easy comparison.
The `name` parameter of the `@bench.T::bench` method can be used to identify the benchmark.

```moonbit
fn fast_fib(n : Int) -> Int {
  if n < 2 {
    return n
  } else {
    let mut a = 0
    let mut b = 1
    for i = 2; i <= n; i = i + 1 {
      let t = a + b
      a = b
      b = t
    }
    b
  }
}

test (b : @bench.T) {
  b.bench(name="naive_fib", fn() { b.keep(fib(20)) })
  b.bench(name="fast_fib", fn() { b.keep(fast_fib(20)) })
}
```

Now you can evaluate which one is faster by looking at the output:

```default
name      time (mean ± σ)         range (min … max) 
naive_fib   21.01 µs ±   0.21 µs    20.76 µs …  21.32 µs  in 10 ×   4632 runs
fast_fib     0.02 µs ±   0.00 µs     0.02 µs …   0.02 µs  in 10 × 100000 runs
```

## Raw Benchmark Statistics

Sometimes users may want to obtain raw benchmark statistics for further analysis.
There is a function `@bench.single_bench` that returns an abstract `Summary` type, which can be serialized into JSON format. The stability of the `Summary` type is not guaranteed to be stable.

In this case, users must ensure that the calculation is not optimized away.
There is no `keep` function available as a standalone function; it is a method of `@bench.T`.

```moonbit
fn collect_bench() -> Unit {
  let mut saved = 0
  let summary : @bench.Summary = @bench.single_bench(name="fib", fn() {
    saved = fib(20)
  })
  println(saved)
  println(summary.to_json().stringify(escape_slash=true, indent=4))
}
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
