///|
fn count_down(start : Int) -> Int {
  loop start {
    n => if n == 0 { break 0 } else { continue n - 1 }
  } nobreak {
    -1
  }
}

///|
test {
  ignore(count_down)
}
