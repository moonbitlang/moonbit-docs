///|
pub fn unwrap_or_zero(value : Int32?) -> Int32 {
  guard value is Some(result) else { 0 }
  result
}

///|
pub fn require_some(value : Int32?) -> Int32 {
  guard! value is Some(result)
  result
}
