// start bench 1
fn fib(n : Int) -> Int {
  if n < 2 {
    return n
  }
  return fib(n - 1) + fib(n - 2)
}

test (b : @bench.T) {
  b.bench(fn() { b.keep(fib(20)) })
}
// end bench 1

// start bench 2
test (b : @bench.T) {
  b.bench(fn() { b.keep(fib(20)) }, count=20)
}
// end bench 2

// start bench 3
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
// end bench 3

// start bench 4
fn collect_bench() -> Unit {
  let mut saved = 0
  let summary : @bench.Summary = @bench.single_bench(name="fib", fn() {
    saved = fib(20)
  })
  println(saved)
  println(summary.to_json().stringify())
}
// end bench 4
