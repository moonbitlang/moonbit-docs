///|
pub fn match_text(text : String) -> Unit {
  lexmatch text with longest {
    re"^(?<word>abc)$" => ()
    _ => ()
  }
}
