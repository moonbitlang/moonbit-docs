///|
fn Int::local_abs(i : Int) -> Int {
  if i > 0 {
    i
  } else {
    -i
  }
}

///|
test {
  inspect((-1).local_abs(), content="1")
}
