///|
pub fn value_or_zero(value : Int32?) -> Int32 {
  match value {
    Some(x) | (None with x = 0) => x
  }
}
