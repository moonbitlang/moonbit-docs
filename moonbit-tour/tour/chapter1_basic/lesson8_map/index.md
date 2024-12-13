# Map

A map is a collection of key-value pairs. Each key is unique in the map, and all keys are associated with a value. It is a mutable collection.

Expression like `{"key1": value1, "key2": value2}` represents a map, called a map
literal. If the key and value type of the map is basic type (`Int`, `String`,
`Bool`, `Double`, etc.), it can be written as map literal. 

In other cases, you can create the map using the `Map::of` function. It takes a
array of two elements tuple, the first element is the key, and the second element
is the value. 

Values in a map can be accessed by the key using the `map[key]` syntax. 

The elements in a map can be updated by `map[key] = new_value`. 

