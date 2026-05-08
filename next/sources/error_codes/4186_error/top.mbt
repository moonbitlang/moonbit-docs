///|
pub fn match_text(text : String) -> Unit {
  lexmatch text with longest {
    "abc" if text.length() > 0 => ()
    _ => ()
  }
}
