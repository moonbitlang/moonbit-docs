// expand pattern

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
    A(x) => inspect("A(\{x})", content="A(1)")
    B(value~) => inspect("B(\{value})")
  }
  let s = S::{ value: 1 }
  match s {
    { value } => println("S(\{value})")
  }
  println("S(\{s.value})")
}
// end expand pattern

// remove unused

///|
priv enum E2 {
  A2
  B2
}

///|
priv struct S2 {}

///|
test {
  ignore(E2::B2)
  match E2::A2 {
    A2 => println("A")
    B2 => println("B")
  }
  ignore(S2::{  })
}
// end remove unused

// make public

///|
pub enum E3 {
  A3(Int)
  B3(value~ : Int)
}

///|
pub struct S3 {
  value : Int
}
// end make public

///|
fn S3::_new() -> S3 {
  { value: 0 }
}

///|
pub fn E3::new_a(value : Int) -> E3 {
  return E3::A3(value)
}

///|
pub fn E3::new_b(value : Int) -> E3 {
  return E3::B3(value~)
}
