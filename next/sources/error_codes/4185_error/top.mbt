///|
fn classify(input : String) -> String {
  lexmatch input with longest {
    ("a", before, "b", after) => before.to_owned() + after.to_owned()
    _ => "none"
  }
}

///|
test {
  ignore(classify)
}
