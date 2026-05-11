pub struct S {
  a : Int
}

pub let a : Int = match S::{ a: 2 } {
  { a: 2 } => 4
  _ => 5
}
