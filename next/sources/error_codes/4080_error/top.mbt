///|
fn f(x : Int32, y : Double) -> Unit {
  ignore((x, y))
}

///|
test {
  f(0) // Error: This function has type (Int32, Double) -> Unit, which requires 2 arguments, but is given 1 argument.
}
