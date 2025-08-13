fn main {
  let value = 1
  match value {
    0..<-10 => println("0..<-10")
  //^~~~~~~
  // Error: Range pattern `a..<b` must satisfy `a < b`.
    _ => println("_")
  }
}