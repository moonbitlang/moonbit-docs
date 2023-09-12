func init {
  let buf = @lib.Buffer::new(4)
  buf.append_int(256)
  buf.append_int(255)
  println(@lib.bytes_to_int(buf.data, 0)) // 256
  println(@lib.bytes_to_int(buf.data, 4)) // 255
  let buf1 = @lib.Buffer::new(4)
  buf1.append_int(257)
  buf.truncate(buf1)
  println(@lib.bytes_to_int(buf.data, 8)) // 257
}
