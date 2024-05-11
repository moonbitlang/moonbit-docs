test {
  let buf = SBuffer::new(4)
  buf.append_int(256)
  buf.append_int(255)
  inspect(bytes_to_int(buf.data, 0), content="256")?
  inspect(bytes_to_int(buf.data, 4), content="255")?
  let buf1 = SBuffer::new(4)
  buf1.append_int(257)
  buf.truncate(buf1)
  inspect(bytes_to_int(buf.data, 8), content="257")?
}
