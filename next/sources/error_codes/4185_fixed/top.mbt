///|
fn classify(input : String) -> String {
  if input =~ (re"a" + re"b", before~, after~) {
    before.to_owned() + after.to_owned()
  } else {
    "none"
  }
}

///|
test {
  inspect(classify("xabz"), content="xz")
}
