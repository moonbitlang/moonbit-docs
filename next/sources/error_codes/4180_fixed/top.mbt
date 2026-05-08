///|
fn classify(input : String) -> String {
  if input =~ re"^if$" {
    "keyword"
  } else {
    "identifier"
  }
}

///|
test {
  inspect(classify("if"), content="keyword")
  inspect(classify("gift"), content="identifier")
}
