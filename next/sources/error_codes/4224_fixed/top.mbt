///|
pub fn classify(text : String) -> String {
  lexmatch text with longest {
    re"^[a-z]+$" => "word"
    _ => "other"
  }
}
