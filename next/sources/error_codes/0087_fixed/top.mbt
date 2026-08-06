///|
pub fn unwrap_or_zero(value : Int?) -> Int {
  guard value is Some(result) else { 0 }
  result
}

///|
pub fn require_some(value : Int?) -> Int {
  guard! value is Some(result)
  result
}
