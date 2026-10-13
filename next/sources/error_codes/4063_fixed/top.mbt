///|
priv trait Number {
  to_int(Self) -> Int32
  to_float(Self) -> Float
}

///|
priv struct A(Int32)

///|
impl Number for A with to_int(self : A) -> Int32 {
  self.0
}

///|
impl Number for A with to_float(self : A) -> Float {
  Float::from_int(self.0)
}

///|
test {
  let value : A = A(42)
  inspect(Number::to_int(value), content="42")
  ignore(Number::to_float(value))
}
