///|
priv enum E {
  A(Int32, Double)
  B(Int32)
}

///|
fn f(value : E) -> Unit {
  match value {
    A(a, _) | B(_) => println(a)
  }
}
