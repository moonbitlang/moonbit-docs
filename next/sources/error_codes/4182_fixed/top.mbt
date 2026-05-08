///|
pub fn match_word(input : String) -> Unit {
  lexmatch input with longest {
    ("[A-Za-z]+", _) => ()
    _ => ()
  }
}
