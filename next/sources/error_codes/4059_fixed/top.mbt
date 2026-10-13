///|
priv struct A(Int32)

///|
fn A::f(self : A) -> Int32 {
  self.0
}

///|
test {
  let value = A(1)
  inspect(value.f(), content="1")
}
