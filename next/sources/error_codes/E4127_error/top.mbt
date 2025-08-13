pub fn may_raise_error() -> Unit!String {
  //                             ^~~~~~
  // Error: Type String is not an error type.
  raise "Failed" // Error: Type String is not an error type.
}