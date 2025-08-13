enum E {
  A(Int, Double, String)
}

fn main {
  match A(0, 1.0) { // Error: This function has type (Int, Double, String) -> E, which requires 3 arguments, but is given 2 arguments.
    A(_, _) => ... // Error: The constructor A requires 3 arguments, but is given 2 arguments.
  }
}