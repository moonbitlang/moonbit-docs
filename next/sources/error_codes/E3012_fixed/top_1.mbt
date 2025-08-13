fn main {
  let s : S = { value: 42 }
  match s {
    { value } => println("Value is: \{value}")
  }
}