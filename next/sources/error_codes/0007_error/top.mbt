///|
priv enum E {
  A(Int32)
  B(value~ : Int32)
}

///|
priv struct S {
  value : Int32
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