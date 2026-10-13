///|
fn Int32::local_abs(i : Int32) -> Int32 {
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
