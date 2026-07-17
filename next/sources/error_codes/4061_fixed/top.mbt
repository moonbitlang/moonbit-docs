///|
priv struct WrapA(@a.A)

///|
impl @a.B for WrapA with to_int(self : WrapA) -> Int {
  let _ = self.0
  0
}

///|
test {
  let value = WrapA(@a.A(1))
  inspect(@a.B::to_int(value), content="0")
}
