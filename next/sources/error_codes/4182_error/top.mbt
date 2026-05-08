///|
const WORD = re"[A-Za-z]+"

///|
pub fn match_word(input : String) -> Unit {
  lexmatch input with longest {
    (WORD, _) => ()
    _ => ()
  }
}
