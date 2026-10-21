///|
const Infinity : Double = 1.0e308 * 1.0e308

///|
const NaN : Double = Infinity - Infinity

///|
pub fn describe(value : Double) -> String {
  match value {
    NaN => "not a number"
    _ => "number"
  }
}
