///|
priv struct MyMap {}

///|
test {
  let map : MyMap = {}
  match map {
    { "a": a, .. } => println("a: \{a}")
    //^~~~~~~~~~~~~~
    // Error: Please implement method `get` for type MyMap to match it with map pattern.
  }
}
