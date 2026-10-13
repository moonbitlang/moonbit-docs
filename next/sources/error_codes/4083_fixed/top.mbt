///|
pub fn value_or(value : Int32?, fallback : Int32) -> Int32 {
  match value {
    Some(result) | (None with result = fallback) => result
  }
}
