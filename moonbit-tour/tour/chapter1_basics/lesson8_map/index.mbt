fn main {
  // Create a map by map literal
  let map1 = { "key1": 1, "key2": 2, "key3": 3 }
  println(map1)
  // You can also create a map by Map::of, from a list of key-value pairs
  let map2 = Map::of([("key1", 1), ("key2", 2), ("key3", 3)])
  println(map1 == map2)

  // Access a value by key
  println(map1.get("key1"))

  // Update a value by key
  map1["key1"] = 10
  println(map1)

  // test a if a key exists
  println(map1.contains("key1"))
}
