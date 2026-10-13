///|
priv struct WrapA(@a.A)

///|
fn WrapA::f(self : WrapA) -> Int32 {
  let _ = self.0
  0
}

///|
test {
  let value = WrapA(@a.A(1))
  inspect(value.f(), content="0")
}
