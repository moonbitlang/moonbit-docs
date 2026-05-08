///|
priv trait Number {
  to_int(Self) -> Int
  to_float(Self) -> Float
}

///|
priv struct A(Int)

///|
impl Number for A with to_int(self : A) -> Int {
  self.0
}

///|
impl Number for A with to_float(self : A) -> Float {
  Float::from_int(self.0)
}

///|
test {
  let value : A = A(42)
  inspect(value.to_int(), content="42")
  ignore(value.to_float())
}
