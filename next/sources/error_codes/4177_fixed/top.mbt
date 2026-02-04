test {
  let a : Array[Byte] = [b'\xFF', b'\x00']
  match a {
    [u8be(value), ..rest] => {
      inspect(value, content="255")
      inspect(rest.length(), content="1")
    }
    _ => fail("")
  }
}
