///|
fn classify(input : String) -> String {
  lexmatch input with shortest {
    "if" => "keyword"
    _ => "identifier"
  }
}

///|
test {
  ignore(classify)
}
