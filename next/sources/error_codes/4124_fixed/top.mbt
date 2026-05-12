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

pub fn use_all() -> (A, A, A, B, B, B) {
  (
    A::A(1),
    A::B(true),
    A::C(1.0),
    B::A(1.0),
    B::B(1),
    B::C(true),
  )
}
