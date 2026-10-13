///|
fn assign_mutable() -> Int32 {
  let mut n = 4
  n = 5
  n
}

///|
test {
  inspect(assign_mutable(), content="5")
}
