///|
fn fib(n : Int) -> UInt64 {
  for i = 0, a = 0UL, b = 1UL; i < n; i = i + 1, a = b, b = a + b {

  } else {
    b
  } where {
    invariant: a <= b,
  }
}
