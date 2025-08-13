test {
  let x : Int = 42
  let buf = @buffer.new()
  let _ : Bytes = buf
    ..write_string("(")
    ..write_object(x)
    ..write_string(")")
    .to_bytes()
}