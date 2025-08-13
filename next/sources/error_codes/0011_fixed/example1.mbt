///|
/// Example using `is` syntax for conditional pattern matching
pub fn example_with_is() -> Unit {
  if Some(1) is Some(x) {
    println(x)
  }
}
