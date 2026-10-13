///|
pub fn f() -> Unit {
  fn h(x~ : Int32) -> Unit {
    //     ^^ Error: Only toplevel functions can have labelled arguments.
    println(x)
  }
  h(x=42)
}
