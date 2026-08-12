///|
pub fn starts_with_digits(input : String) -> Bool {
  lexmatch input {
    (re"^[0-9]+", after=_) => true
    _ => false
  }
}
