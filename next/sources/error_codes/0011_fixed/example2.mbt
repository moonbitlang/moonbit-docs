///|
/// Example using wildcard pattern to catch all remaining cases
pub fn example_with_wildcard() -> Unit {
  match Some(1) {
    Some(x) => println(x)
    _ => println("Other")
  }
}
