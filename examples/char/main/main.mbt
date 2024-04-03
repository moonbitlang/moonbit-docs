test {
  @assertion.assert_true(@lib.is_alpha('a'))?
  @assertion.assert_false(@lib.is_alpha('3'))?
  @assertion.assert_true(@lib.is_numeric('1'))?
  @assertion.assert_false(@lib.is_numeric('b'))?
  @assertion.assert_true(@lib.is_alphanumeric('a'))?
  @assertion.assert_eq(@lib.to_lower('H'), 'h')?
  @assertion.assert_eq(@lib.to_upper('c'), 'C')?
  @assertion.assert_true(@lib.is_whitespace(' '))?
  @assertion.assert_eq(@lib.next('Z'), Some('['))?
  @assertion.assert_eq(@lib.prev('A'), Some('@'))?
}

