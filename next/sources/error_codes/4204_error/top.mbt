///|
fn count_down(n : Int32) -> Int32 {
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
