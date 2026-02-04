fn f(x: Bytes) -> Unit {
  match x {
    [0x12, u1be(_), u7be(_), 0x34, ..] => ()
    _ => ()
  }
}
