///|
pub fn value_or_zero(value : Int32?) -> Int32 {
  result~: {
    guard value is Some(result) else { break result~ 0 }
    result
  }
}
