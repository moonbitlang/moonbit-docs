///|
pub fn classify(input : String) -> String {
  lexscan input with longest {
    (re"^[a-z]+", after=_) => "word"
    _ => "other"
  }
}
