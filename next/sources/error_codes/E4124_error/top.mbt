enum A {
  A(Int)
  B(Bool)
  C(Double)
}

enum B {
  A(Double)
  B(Int)
  C(Bool)
}

fn main {
  let a = A(1) // Error: The constructor A is ambiguous: it may come from type B or A.
}