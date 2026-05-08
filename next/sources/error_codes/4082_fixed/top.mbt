///|
priv enum E {
  A(Int, Double)
  B(Int)
}

///|
fn f(value : E) -> Unit {
  match value {
    A(a, _) | B(a) => println(a)
  }
}

///|
fn use_second(value : E) -> Unit {
  match value {
    A(_, b) => println(b)
    B(_) => ()
  }
}

///|
test {
  f(A(1, 2.0))
  f(B(1))
  use_second(A(1, 2.0))
}
