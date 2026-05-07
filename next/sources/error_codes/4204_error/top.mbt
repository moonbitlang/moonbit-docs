///|
fn count_down(n : Int) -> Int {
  loop n {
    0 => break 0
    i => continue i - 1
  } nobreak {
    -1
  }
}

///|
test {
  ignore(count_down)
}
