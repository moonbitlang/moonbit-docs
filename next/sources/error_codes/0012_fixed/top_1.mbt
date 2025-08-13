fn main {
  match Some(1) {
    Some(a) => println("Some(\{a})")
    _ => println("_")
  }
}
