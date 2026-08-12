///|
pub fn classify(input : String, allow : Bool) -> String {
  lexmatch input {
    re"^[a-z]+$" if allow => "word"
    _ => "other"
  }
}
