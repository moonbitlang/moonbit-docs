///|
test {
  let char : Char = '\u{1F600}'
  let byte : Byte = b'\x41'
  ignore(char)
  inspect(byte.to_int(), content="65")
}
