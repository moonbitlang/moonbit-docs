///|
pub fn[T : @lexbuf.Scannable + @lexbuf.BytesScannable] scan_word(
  target : T,
) -> Bool {
  lexscan target {
    re"^[a-z]+" => true
    _ => false
  }
}
