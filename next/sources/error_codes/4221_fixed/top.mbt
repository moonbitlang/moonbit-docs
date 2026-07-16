///|
pub fn value_or_zero(value : Int?) -> Int {
  match value {
    Some(x) | (None with x = 0) => x
  }
}
