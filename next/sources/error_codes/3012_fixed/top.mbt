///|
fn use_map_pattern(map : Map[String, Int32]) -> Unit {
  match map {
    { "value": value, .. } => println("Value is: \{value}")
    _ => println("No value")
  }
}

///|
test {
  let map : Map[String, Int32] = { "value": 42 }
  use_map_pattern(map)
}
