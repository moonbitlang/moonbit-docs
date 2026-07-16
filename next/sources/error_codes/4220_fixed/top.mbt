///|
pub fn first_word(input : String) -> StringView {
  lexscan input with longest {
    (re"^[a-z]+" as word, after=_) => word
    _ => ""
  }
}
