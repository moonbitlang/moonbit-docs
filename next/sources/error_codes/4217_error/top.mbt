///|
pub fn classify(input : String, allow : Bool) -> String {
  lexscan input {
    re"^[a-z]+$" if allow => "word"
    _ => "other"
  }
}
