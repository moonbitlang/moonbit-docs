///|
pub fn starts_with_digits(input : String) -> Bool {
  lexscan input {
    (re"^[0-9]+", after=_) => true
    _ => false
  }
}
