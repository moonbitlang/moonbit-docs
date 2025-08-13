struct S { a : Int; b: Int }
let a : Int = match S::{ a: 2, b: 3 } {
  { a: 2, b: 3 } => 4
  { a: 2, .. } => 5
  _ => 6
}