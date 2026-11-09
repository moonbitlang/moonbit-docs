///|
pub const WORD = re"[a-z]+"

///|
pub fn matches(text : String) -> Bool {
  text =~ WORD
}

///|
test {
  assert_true(matches("hello"))
  assert_false(matches("123"))
}
