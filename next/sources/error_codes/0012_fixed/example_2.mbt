///|
fn example_specific_pattern() -> Unit {
  match Some(1) {
    None => println("_")
    Some(a) => println("Some(\{a})")
  }
}
