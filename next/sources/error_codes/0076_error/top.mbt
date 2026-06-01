///|
fn classify(input : String) -> String {
  lexmatch input {
    "if" => "keyword"
    _ => "other"
  }
}

///|
test {
  ignore(classify)
}
