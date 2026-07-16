///|
fn classify(input : String) -> String {
  lexmatch input with longest {
    ("if|[a-z]*" as token) => token.to_owned()
    _ => "other"
  }
}

///|
test {
  inspect(classify("iff"), content="iff")
}
