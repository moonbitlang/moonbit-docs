///|
pub fn match_text(text : String) -> Unit {
  lexscan text with longest {
    _ => ()
  }
}
