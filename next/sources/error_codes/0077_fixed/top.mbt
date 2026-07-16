///|
fn classify(input : String) -> String {
  lexscan input with longest {
    re"^(if|[a-z]*)$" as token => token.to_owned()
    _ => "other"
  }
}

///|
test {
  inspect(classify("iff"), content="iff")
}
