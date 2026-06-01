///|
fn is_keyword(input : String) -> Bool {
  input =~ re"^if$"
}

///|
test {
  ignore(is_keyword)
}
