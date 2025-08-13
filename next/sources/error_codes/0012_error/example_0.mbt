///|
/// Example function showing unreachable code after an early return
fn unreachable_early_return() -> Unit {
  return
  println("Hello, World!") // Warning: Unreachable code
}
