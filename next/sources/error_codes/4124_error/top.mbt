pub enum A {
  A(Int)
  B(Bool)
  C(Double)
}

pub enum B {
  A(Double)
  B(Int)
  C(Bool)
}

pub fn use_a() -> Unit {
  ignore(A(1))
}
