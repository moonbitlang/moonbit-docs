///|
pub fn ends_with_digits(input : String) -> Bool {
  lexscan input {
    (re"[0-9]+$", before=_) => true
    _ => false
  }
}
