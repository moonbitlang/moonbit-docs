///|
pub let x : Int32 = {
  return 42
}
//                 ^^^^^^^^^ Error: Return must be inside a function.

///|
pub let y : Int32 = if x == 42 {
  x + 1
} else {
  return 0
  //  ^^^^^^^^ Error: Return must be inside a function.
}
