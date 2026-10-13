///|
pub fn f(xs : Array[Int32]) -> Int32 {
  for i in xs {
    ignore(i)
  } nobreak {
    break 42
  }
  //  ^^^^^^^^ Error: 'break' outside of a loop
}

///|
pub fn g(x : Int32) -> Unit {
  continue x
  // ^^^^^^^^ Error: 'continue' outside of a loop
}
