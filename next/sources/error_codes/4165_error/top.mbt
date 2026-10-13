///|

///|
fn first_and_rest(value : Int32) -> Int32 {
  match value {
    [head, .. _tail] => head
    _ => 0
  }
}

///|
test {
  ignore(first_and_rest)
}
