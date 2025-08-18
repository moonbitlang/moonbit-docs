///|
fn Int::abs(i : Int) -> Int {
  if i > 0 {
    i
  } else {
    -i
  }
}

///|
test {
  inspect((-1).abs(), content="1")
}
