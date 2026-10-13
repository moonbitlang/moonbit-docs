///|
pub fn first_or_default(xs : Array[Int32]) -> Int32 {
  for x in xs {
    if x > 0 {
      break x
    }
  } nobreak {
    0
  }
}

///|
pub fn count_down(from : Int32) -> Unit {
  for i = from; i > 0; i = i - 1 {
    if i % 2 == 0 {
      continue
    }
    println(i)
  }
}
