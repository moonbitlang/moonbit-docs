///|
pub fn ends_with_digits(input : String) -> Bool {
  lexmatch input {
    (re"[0-9]+$", before=_) => true
    _ => false
  }
}
