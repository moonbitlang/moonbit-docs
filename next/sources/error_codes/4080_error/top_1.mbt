///|
priv enum E {
  A(Int32, Double, String)
}

///|
test {
  match A(0, 1.0) { // Error: This function has type (Int32, Double, String) -> E, which requires 3 arguments, but is given 2 arguments.
    A(_, _) => () // Error: The constructor A requires 3 arguments, but is given 2 arguments.
  }
}
