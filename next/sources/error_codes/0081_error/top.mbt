///|
pub fn starts_with_digits(input : String) -> Bool {
  lexscan input {
    re"^[0-9]+" => true
    _ => false
  }
}
