type! ArithmeticError {
  DivisionByZero
}

pub fn checked_div(a : Double, b : Double) -> Double {
  if b == 0.0 {
    raise DivisionByZero // Error: raise can only be used inside ...
  }
  return a / b
}