pub enum A {
  A(Int32)
  B(Bool)
  C(Double)
}

pub enum B {
  A(Double)
  B(Int32)
  C(Bool)
}

pub fn use_a() -> Unit {
  ignore(A(1))
}
