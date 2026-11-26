///|
pub fn scan_word() -> Bool {
  let scan = fn(target) {
    lexscan target {
      re"^[a-z]+" => true
      _ => false
    }
  }
  scan(@lexbuf.StringScanner("hello"))
}
