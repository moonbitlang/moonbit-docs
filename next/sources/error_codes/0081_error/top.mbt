///|
pub fn starts_with_digits(input : String) -> Bool {
  lexmatch input {
    re"^[0-9]+" => true
    _ => false
  }
}
