///|
pub fn match_text(text : String, part : String) -> Unit {
  lexmatch text with longest {
    ("\{part}", _) => ()
    _ => ()
  }
}
