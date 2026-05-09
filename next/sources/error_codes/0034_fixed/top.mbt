///|
pub fn check(value : Json) -> Int {
  fn classify(input : Json) {
    match input {
      Json::Null => 0
      _ => 1
    }
  }

  classify(value)
}
