///|
pub fn f(x : Int32, y : Int32) -> Unit {
  for i = 0; i < x; i = i + 1 {
    for j = 0; j < y; j = j + 1 {
      if i + j > 10 {
        break
      }
      println(i + j)
    }
  }
}
