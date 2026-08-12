///|
pub fn classify(text : String) -> String {
  lexmatch text with longest {
    re"^.*$" => "text"
  }
}
