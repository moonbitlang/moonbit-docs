///|
test {
  let map : Map[String, Int32] = { "value": 42 }
  match map {
    { "value": value, value, .. } => println("Value is: \{value}") // Error: Struct pattern and map pattern cannot be mixed.
    _ => println("No value")
  }
}
