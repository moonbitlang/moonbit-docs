///|
test {
  let x : Int = 42
  let buf = Buffer()
  let bytes : Bytes = buf
    ..write_string_utf8("(")
    ..write_utf8(x)
    ..write_string_utf8(")")
    .to_bytes()
  ignore(bytes)
}
