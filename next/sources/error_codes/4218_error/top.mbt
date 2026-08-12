///|
pub fn classify(input : String) -> String {
  lexmatch input with longest {
    re"[a-z]+" => "word"
    _ => "other"
  }
}
