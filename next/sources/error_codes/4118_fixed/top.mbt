///|
priv struct MyMap {
  entries : Map[String, Int]
}

///|
fn MyMap::get(self : MyMap, key : String) -> Int? {
  self.entries.get(key)
}

///|
test {
  let map : MyMap = { entries: { "a": 1, "b": 2, "c": 3 } }
  match map {
    { "a": a, .. } => println("a: \{a}")
    _ => println("missing")
  }
}
