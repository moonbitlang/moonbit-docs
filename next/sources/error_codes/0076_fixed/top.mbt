///|
fn classify(input : String) -> String {
  if input =~ re"^if$" {
    "keyword"
  } else {
    "other"
  }
}

///|
test {
  ignore(classify)
}
