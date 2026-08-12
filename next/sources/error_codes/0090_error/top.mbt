///|
pub fn classify(text : String) -> String {
  lexmatch text {
    re"^a.*$" => "starts with a"
    re"^ab.*$" => "starts with ab"
    _ => "other"
  }
}
