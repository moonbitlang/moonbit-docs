///|
fn Int32::abs(i : Int32) -> Int32 {
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
