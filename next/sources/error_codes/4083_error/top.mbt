///|
pub fn value_or(value : Int?, result : Int) -> Int {
  match value {
    Some(result) | (None with result = result) => result
  }
}
