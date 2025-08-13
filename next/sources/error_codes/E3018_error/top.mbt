fn main {
  let a = 3
  match 0 {
    0..<a => println("Between 0 and 3") // Error: Bounds of range pattern must be constant, named constant or wildcard.
    _ => println("Not between 0 and 3")
  }
}