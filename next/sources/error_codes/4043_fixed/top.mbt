pub struct S {
  a : Int32
}

pub let a : Int32 = match S::{ a: 2 } {
  { a: 2 } => 4
  _ => 5
}
