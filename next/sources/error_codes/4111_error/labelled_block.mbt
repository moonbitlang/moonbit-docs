///|
pub fn value_or_zero(value : Int?) -> Int {
  result~: {
    guard value is Some(result) else { break }
    result
  }
}
