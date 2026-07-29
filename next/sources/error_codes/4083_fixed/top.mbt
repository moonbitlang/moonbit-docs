///|
pub fn value_or(value : Int?, fallback : Int) -> Int {
  match value {
    Some(result) | (None with result = fallback) => result
  }
}
