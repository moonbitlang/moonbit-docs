///|
pub fn classify(text : String) -> String {
  lexmatch text {
    re"^ab.*$" => "starts with ab"
    re"^a.*$" => "starts with a"
    _ => "other"
  }
}
