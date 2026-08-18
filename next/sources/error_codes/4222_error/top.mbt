///|
pub fn scan_text(text : String) -> Unit {
  lexscan text with longest {
    _ => ()
  }
}
