///|
fn count_down(start : Int) -> Int {
  let mut n = start
  while true {
    if n == 0 {
      break 0
    }
    n = n - 1
  } nobreak {
    -1
  }
}

///|
test {
  inspect(count_down(3), content="0")
}
