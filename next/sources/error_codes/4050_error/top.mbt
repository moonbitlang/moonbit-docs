///|
pub let a : Int32 = f() // Error: Definition cycle detected : a -> f -> a

///|
fn f() -> Int32 { // Error: Definition cycle detected : a -> f -> a
  a
}
