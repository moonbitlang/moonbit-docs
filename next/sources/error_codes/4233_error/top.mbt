///|
pub fn matches(input : @lexbuf.Lexbuf) -> Bool {
  lexscan input {
    re"^[01]*1[01]{20}$" => true
    _ => false
  }
}
