///|
fn h(x~ : Int32) -> Unit {
  println(x)
}

///|
pub fn call_toplevel() -> Unit {
  h(x=42)
}
