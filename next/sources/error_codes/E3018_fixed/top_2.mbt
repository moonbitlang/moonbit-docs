fn main {
  let a = 3
  match 0 {
    0..<_ => println("Big than or equal to 0")
    _ => println("Less than 0")
  }
}