type MyMap[K, V] Map[K, V]

fn main {
  let map : MyMap[String, Int] = { "a": 1, "b": 2, "c": 3 }
  match map {
    { "a": a, .. } => println("a: \{a}")
  //^~~~~~~~~~~~~~
  // Error: Please implement method `op_get` for type MyMap[String, Int] to match it with map pattern.
  }
}