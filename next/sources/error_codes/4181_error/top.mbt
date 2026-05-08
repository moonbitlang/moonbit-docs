///|
pub fn match_text(text : String) -> Unit {
  lexmatch text with longest {
    ("(?<word>abc)", _) => ()
    _ => ()
  }
}
