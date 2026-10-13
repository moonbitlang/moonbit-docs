pub fn check(value : Int32?) -> Int32 {
  match value {
    None => 0
    Some(value) => value
  }
}
