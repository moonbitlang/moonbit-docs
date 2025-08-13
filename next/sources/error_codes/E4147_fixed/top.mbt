fn main {
  let value = 1
  match value {
    -10..<0 => println("0..=10")
    _ => println("_")
  }
}