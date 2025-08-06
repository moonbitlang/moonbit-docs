///|
priv enum E {
  A(Int)
  B(value~ : Int)
}

///|
priv struct S {
  value : Int
}

///|
test {
  ignore(B(value=1))
  match A(1) {
    A(_) => println("A")
    B(_) => println("B")
  }
  ignore(S::{ value : 1 })
}