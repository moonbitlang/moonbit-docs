pub fn f(x: Int) -> Int {
  for i = 0, acc = 0; i < x; i = i + 1, acc = acc + i {
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Error: The for loop is
//                                                      not expected to yield a
//                                                      value, please add an
//                                                      `else` branch.
  }
}

pub fn g(x: Int) -> Int {
  for i in 0..=x {
  }
}