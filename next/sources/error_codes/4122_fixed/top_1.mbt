///|
pub fn checked_div_noraise(a : Double, b : Double) -> Double noraise {
  try {
    if b == 0.0 {
      raise DivisionByZero
    }
    return a / b
  } catch {
    DivisionByZero => @double.not_a_number
  }
}
