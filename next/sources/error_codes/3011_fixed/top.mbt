///|
fn assign_mutable() -> Int {
  let mut n = 4
  n = 5
  n
}

///|
test {
  inspect(assign_mutable(), content="5")
}
