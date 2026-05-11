pub struct S {
  a : Int
}

pub let a : Int = match S::{ a: 2, a: 3 } {
  { a: 2, a: 3 } => 4
  _ => 5
}
