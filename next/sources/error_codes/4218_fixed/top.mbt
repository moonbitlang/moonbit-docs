///|
pub fn classify(input : String) -> String {
  lexmatch input with longest {
    (re"^[a-z]+", after=_) => "word"
    _ => "other"
  }
}
