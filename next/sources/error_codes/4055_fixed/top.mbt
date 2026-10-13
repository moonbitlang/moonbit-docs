///|
priv struct A {
  a : Int32
  b : Double
}

///|
test {
  let value : A = { a: 1, b: 2.0 }
  inspect(value.a, content="1")
  inspect(value.b, content="2")
}
