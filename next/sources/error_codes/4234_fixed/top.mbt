///|
pub fn matches(text : String) -> Bool {
  text =~ re"abc"
}

///|
test {
  assert_true(matches("abc"))
  assert_false(matches("123"))
}
