pub fn fib(n : Int) -> Int64 {
  loop 0L, 1L, n {
    a, _, 0 => a
    a, b, n => continue b, a + b, n - 1
  }
}