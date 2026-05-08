///|
pub suberror ExampleError {
  Failed
}

///|
pub fn may_raise_error(input : Int) -> Unit raise ExampleError {
  if input == 42 {
    return
  }
  raise Failed
}

///|
pub fn caller() -> Unit raise ExampleError {
  may_raise_error(42)
}
