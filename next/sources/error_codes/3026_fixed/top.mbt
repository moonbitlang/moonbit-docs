///|
pub fn value_or_zero(value : Int?) -> Int {
  match value {
    Some(result) | (None with result = 0) => result
  }
}
