# Map

A map is a collection of key-value pairs. Each key is unique in the map, and all keys are associated with a value. It is a mutable collection.

An expression like `{"key1": value1, "key2": value2}` represents a map, called a *map literal*.
If the key and value types of the map are basic types (`Int`, `String`,`Bool`, `Double`, etc.),
then the map can be written as a *map literal*.

In other cases, you can create the map using the `Map::of` function. It takes an array of two-element tuples, where the first element is the key and the second element is the value.

Values in a map can be accessed by the key using the `map[key]` syntax.

The elements in a map can be updated using the syntax: `map[key] = new_value`.
