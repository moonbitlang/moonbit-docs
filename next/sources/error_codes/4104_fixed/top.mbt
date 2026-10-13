///|
pub fn g(x : Int32, y : Int32) -> Int32 {
  for i = x, j = y; i + j < 10; i = i + 1, j = j + 1 {
    if i < j {
      continue i + 2, j + 1
    } else {
      continue
    }
  } nobreak {
    42
  }
}
