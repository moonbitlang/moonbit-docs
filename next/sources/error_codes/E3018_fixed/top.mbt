const A = 3
fn main {
  match 0 {
    0..<A => println("Between 0 and 3")
    _ => println("Not between 0 and 3")
  }
}