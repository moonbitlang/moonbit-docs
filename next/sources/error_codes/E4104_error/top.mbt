pub fn f(x: Int, y: Int) -> Int {
  loop x, y {
    0, 0 => 0
    a, _ => continue a - 1
//          ^^^^^^^^^^^^^^ Error: Current loop expects 2 arguments, but
//                                `continue` is supplied with 1 arguments
  }
}

pub fn g(x : Int, y : Int) -> Int {
  for i = x, j = y; i + j < 10; i = i + 1, j = j + 1 {
    if i < j {
      continue i + 2, j + 1, i + j
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Error: Current loop expects 2 arguments, but
//                                       `continue` is supplied with 3 arguments
    }
  } else {
    42
  }
}