fn fib(num : Int) -> Int {
  fn aux(n, acc1, acc2) {
    match n {
      0 => acc1
      1 => acc2
      _ => aux(n - 1, acc2, acc1 + acc2)
    }
  }

  aux(num, 0, 1)
}

pub fn test(n : Int, count : Int) -> Int {
  let mut i = 0
  let mut res = 0
  while i < count, i = i + 1 {
    res = fib(n)
  }
  res
}
