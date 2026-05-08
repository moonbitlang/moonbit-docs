///|
pub fn first_or_default(xs : Array[Int]) -> Int {
  for x in xs {
    if x > 0 {
      break x
    }
  } nobreak {
    0
  }
}

///|
pub fn count_down(from : Int) -> Unit {
  for i = from; i > 0; i = i - 1 {
    if i % 2 == 0 {
      continue
    }
    println(i)
  }
}
