fn main {
  println("\nfor-in loop:")
  let array = [1, 2, 3]
  for element in array {
    println("element: \{element}")
  }
  
  println("\nfor-in loop for map:")
  let map = { "key1": 1, "key2": 2, "key3": 3 }
  for k, v in map {
    println("key: \{k}, value: \{v}")
  }
}
