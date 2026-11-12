///|
pub fn matches(input : @lexbuf.Lexbuf) -> Bool {
  lexscan input {
    re"^[01]+$" as bits =>
      bits.length() >= 21 && bits[bits.length() - 21] == '1'
    _ => false
  }
}

///|
test {
  for (text, expected) in [
    ("100000000000000000000", true),
    ("000000000000000000000", false),
    ("1", false),
    ("10000000000000000000x", false),
  ] {
    let chunks = [text].iter()
    let input = @lexbuf.Lexbuf::from_fn(() => chunks.next())
    assert_eq(matches(input), expected)
  }
}

///|
test "rejected binary input is consumed" {
  let chunks = ["1"].iter()
  let input = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  assert_false(matches(input))
  let at_end = lexscan input {
    re"^." => false
    _ => true
  }
  assert_true(at_end)
}
