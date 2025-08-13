///|
fn example_proper_order() -> Unit {
  match Some(1) {
    Some(a) => println("Some(\{a})")
    _ => println("_")
  }
}
