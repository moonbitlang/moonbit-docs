# Visibility Attribute

#### NOTE
This topic does not covered the access control. To learn more about `pub`, `pub(all)` and `priv`, see [Access Control](../packages.md#id1).

The `#visibility` attribute is similar to the `#deprecated` attribute, but it is used to hint that a type will change its visibility in the future.
For outside usages, if the usage will be invalidated by the visibility change in future, a warning will be emitted.

```moonbit
// in @util package
#visibility(change_to="readonly", "Point will be readonly in the future.")
pub(all) struct Point {
  x : Int
  y : Int
}

#visibility(change_to="abstract", "Use new_text and new_binary instead.")
pub(all) enum Resource {
  Text(String)
  Binary(Bytes)
}

pub fn new_text(str : String) -> Resource {
  ...
}

pub fn new_binary(bytes : Bytes) -> Resource {
  ...
}

// in another package
fn main {
  let p = Point::{ x: 1, y: 2 } // warning
  let { x, y } = p // ok
  println(p.x) // ok
  match Resource::Text("") { // warning
    Text(s) => ... // waning
    Binary(b) => ... // warning
  }
}

```

The `#visibility` attribute takes a required `change_to` argument and an
optional `message` argument.

- The `change_to` argument is a string that indicates the new visibility of the type. It can be either `"abstract"` or `"readonly"`.

  | `change_to`   | Invalidated Usages                                                                                                     |
  |---------------|------------------------------------------------------------------------------------------------------------------------|
  | `"readonly"`  | Creating an instance of the type or mutating the fields of the instance.                                               |
  | `"abstract"`  | Creating an instance of the type, mutating the fields of the instance, pattern matching, or accessing fields by label. |
- The optional `message` argument is a string that provides additional information about the visibility change.
