///|
priv enum E {
  A(Int, Double)
  B(Int)
}

///|
fn f(value : E) -> Unit {
  match value {
    A(a, _) | B(_) => println(a)
  }
}
