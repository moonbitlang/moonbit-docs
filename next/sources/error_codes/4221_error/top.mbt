///|
pub fn value_or_zero(value : Int?) -> Int {
  match value {
    Some(x) | (None with x = { return 0 }) => x
  }
}
