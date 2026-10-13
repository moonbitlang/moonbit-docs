///|
priv enum E {
  A(Int32, Double, String)
}

///|
test {
  match A(0, 1.0, "foo") {
    A(x, y, z) => ignore((x, y, z))
  }
}
