///|
pub fn f(xs : Array[Int]) -> Int {
  for i in xs {
    ignore(i)
  } nobreak {
    break 42
  }
  //  ^^^^^^^^ Error: 'break' outside of a loop
}

///|
pub fn g(x : Int) -> Unit {
  continue x
  // ^^^^^^^^ Error: 'continue' outside of a loop
}
