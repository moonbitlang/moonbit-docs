///|
test {
  let map : Map[String, Int32] = { "a": 1, "b": 2, "c": 3 }
  match map {
    { "a": a, .. } => println("a: \{a}")
    _ => println("missing")
  }
}
