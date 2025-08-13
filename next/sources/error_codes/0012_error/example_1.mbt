///|
// Example function showing unreachable pattern matching
fn unreachable_match_pattern() -> Unit {
  match Some(1) {
    _ => println("_")
    Some(a) => println("Some(\{a})") // Warning: Unreachable code
  }
}
