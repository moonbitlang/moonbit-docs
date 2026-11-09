///|
test "byte regex captures" {
  let input : Bytes = b"\xff123!"
  lexmatch input {
    ((reb"^." as first) + (reb"[0-9]+" as digits), after=rest) => {
      let byte : Byte = first
      let number : BytesView = digits
      assert_eq(byte, 0xff)
      assert_eq(number, b"123"[:])
      assert_eq(rest, b"!"[:])
    }
    _ => fail("expected a byte followed by digits")
  }
  assert_true(input =~ reb"^\xff")
}
