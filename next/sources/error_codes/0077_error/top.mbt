///|
fn is_keyword(input : String) -> Bool {
  lexmatch input with longest {
    "if" => true
    _ => false
  }
}

///|
test {
  ignore(is_keyword)
}
