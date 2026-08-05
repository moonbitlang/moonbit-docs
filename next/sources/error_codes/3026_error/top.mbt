///|
pub fn value_or_zero(value : Int?) -> Int {
  match value {
    (None with result = 0) => result
    Some(result) => result
  }
}
