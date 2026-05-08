///|
priv trait T {
  f(Self) -> Int
}

///|
priv struct A(Int)

///|
impl T for A with f(self : A) -> Int {
  self.0
}

///|
test {
  let value : A = A(1)
  inspect(value.f(), content="1")
}
