///|
fn make_buffer() -> @buffer.Buffer {
  @buffer.new()
}

///|
test {
  ignore(make_buffer())
}
