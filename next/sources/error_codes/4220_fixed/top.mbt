///|
pub fn first_word(input : String) -> StringView {
  lexmatch input with longest {
    (re"^[a-z]+" as word, after=_) => word
    _ => ""
  }
}
