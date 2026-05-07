///|
fn outer_sum(array : Array[Int]) -> Int {
  match array {
    [fst, .., snd] => fst + snd
    _ => 0
  }
}

///|
test {
  inspect(outer_sum([1, 2, 3, 4, 5]), content="6")
}
