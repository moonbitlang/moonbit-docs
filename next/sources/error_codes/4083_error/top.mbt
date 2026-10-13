///|
pub fn value_or(value : Int32?, result : Int32) -> Int32 {
  match value {
    Some(result) | (None with result = result) => result
  }
}
