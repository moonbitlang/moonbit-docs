///|
priv struct A(Int)

///|
fn A::f(self : A) -> Int {
  self.0
}

///|
test {
  let value = A(1)
  inspect(value.f(), content="1")
}
