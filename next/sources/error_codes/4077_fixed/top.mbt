///|
priv trait T {
  f(Self) -> Int32
}

///|
priv struct A(Int32)

///|
impl T for A with f(self : A) -> Int32 {
  self.0
}

///|
test {
  let value : A = A(1)
  inspect(T::f(value), content="1")
}
