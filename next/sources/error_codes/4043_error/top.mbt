pub struct S {
  a : Int32
}

pub let a : Int32 = match S::{ a: 2, a: 3 } {
  { a: 2, a: 3 } => 4
  _ => 5
}
