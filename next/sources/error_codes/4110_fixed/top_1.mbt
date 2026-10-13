///|
pub fn first_index_or_default(x : Int32) -> Int32 {
  for i in 0..<=x {
    break i
  } nobreak {
    42
  }
}
