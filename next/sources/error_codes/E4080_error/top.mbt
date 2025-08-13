fn f(x : Int, y : Double) -> Unit {
  ignore((x, y))
}

fn main {
  f(0) // Error: This function has type (Int, Double) -> Unit, which requires 2 arguments, but is given 1 argument.
}