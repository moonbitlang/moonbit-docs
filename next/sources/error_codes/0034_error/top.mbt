///|
pub fn check(value : Json) -> Int {
  fn classify(input) {
    match input {
      Null => 0
      _ => 1
    }
  }

  classify(value)
}
