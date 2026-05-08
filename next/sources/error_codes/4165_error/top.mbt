///|

///|
fn first_and_rest(value : Int) -> Int {
  match value {
    [head, .. _tail] => head
    _ => 0
  }
}

///|
test {
  ignore(first_and_rest)
}
