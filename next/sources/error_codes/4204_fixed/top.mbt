///|
fn count_down(n : Int) -> Int {
  for i = n {
    if i == 0 {
      break 0
    }
    continue i - 1
  }
}

///|
test {
  inspect(count_down(3), content="0")
}
