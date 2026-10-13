///|
pub fn value_or_zero(value : Int32?) -> Int32 {
  match value {
    Some(result) | (None with result = 0) => result
  }
}
