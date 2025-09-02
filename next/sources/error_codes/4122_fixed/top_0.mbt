///|
suberror ArithmeticError {
  DivisionByZero
}

///|
pub fn checked_div(a : Double, b : Double) -> Double raise ArithmeticError {
  ...
}

///|
pub fn rethrow() -> Unit raise {
  ...
}

///|
pub fn catch_all() -> Double raise {
  ...
}
