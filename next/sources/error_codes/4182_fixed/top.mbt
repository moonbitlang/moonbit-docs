///|
pub fn match_word(input : String) -> Unit {
  lexscan input with longest {
    (re"^[A-Za-z]+", after=_) => ()
    _ => ()
  }
}
