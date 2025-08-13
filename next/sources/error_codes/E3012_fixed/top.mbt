fn main {
  let s : S = { value: 42 }
  match s {
    { "value": value } => println("Value is: \{value}")
    _ => println("No value")
  }
}