pub fn checked_div(a : Double, b : Double) -> Double {
  try {
    if b == 0.0 {
      raise DivisionByZero // Error: raise can only be used inside ...
    }
    return a / b
  } catch {
    _ => {
      println("DivisionByZero")
      @double.not_a_number
    }
  }
}