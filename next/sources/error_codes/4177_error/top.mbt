test {
  let a : Array[Byte] = [b'\xFF', b'\x00']
  match a {
    [u1be(flag), ..rest] => {
      inspect(flag, content="1")
      inspect(rest.length(), content="1")
    }
    _ => fail("")
  }
}
