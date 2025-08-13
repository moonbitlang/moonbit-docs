pub fn f() -> Unit {
  fn h(x~: Int) -> Unit {
//     ^^ Error: Only toplevel functions can have labelled arguments.
    println(x)
  }
  h(x=42)
}