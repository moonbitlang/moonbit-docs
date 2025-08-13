pub fn g(x: Int) -> Int {
  for i in 0..=x {
    if i == 42 {
      break
//    ^^^^^ Error: Current loop has result type Int, but `break` is supplied
//                 with no arguments.
    }
  } else {
    0
  }
}