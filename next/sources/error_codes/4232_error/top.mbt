///|
pub const WORD = re"[a-z]+"

///|
pub fn matches(value : Regex) -> Bool {
  match value {
    WORD => true
    _ => false
  }
}
