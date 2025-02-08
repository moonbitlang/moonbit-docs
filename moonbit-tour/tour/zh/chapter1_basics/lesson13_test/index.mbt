test {
  assert_eq!(1, 1 + 2)
  assert_false!(1 == 2)
  assert_true!([1,2,3] == [1,2,3])
}

test {
  inspect!(fib(5))
  inspect!([1,2,3,4].map(fib))
}

// Add test name to make it more descriptive.
test "fibonacci" {
  inspect!(fib(5), content="5")
  inspect!(fib(6), content="8")
}

fn fib(n : Int) -> Int {
  if n < 2 {
    n
  } else {
    fib(n - 1) + fib(n - 2)
  }
}

