///|

///|
fn first_or_zero(values : Array[Int]) -> Int {
  match values {
    [head, .. _tail] => head
    [] => 0
  }
}

///|
test {
  inspect(first_or_zero([1, 2, 3]), content="1")
  inspect(first_or_zero([]), content="0")
}
