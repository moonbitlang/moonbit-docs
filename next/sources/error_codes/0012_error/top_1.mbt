fn main {
  match Some(1) {
    _ => println("_")
    Some(a) => println("Some(\{a})") // Warning: Unreachable code
  }
}
