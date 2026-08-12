///|
pub fn first_word(input : String) -> StringView {
  lexmatch input with longest {
    (re"^[a-z]+" as word, before=_) => word
    _ => ""
  }
}
