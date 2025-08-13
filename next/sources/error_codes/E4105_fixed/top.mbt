pub fn g(x: Int) -> Int {
  for i in 0..=x {
    if i == 42 {
      break i
    }
  } else {
    0
  }
}