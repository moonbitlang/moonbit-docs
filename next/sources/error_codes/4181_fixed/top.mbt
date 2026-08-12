///|
pub fn match_text(text : String) -> Unit {
  lexmatch text with longest {
    (re"^(abc)$" as word) => ignore(word)
    _ => ()
  }
}
