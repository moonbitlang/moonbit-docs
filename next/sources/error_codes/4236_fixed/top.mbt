///|
pub fn[T : @lexbuf.Scannable] scan_word(target : T) -> Bool {
  lexscan target {
    re"^[a-z]+" => true
    _ => false
  }
}
