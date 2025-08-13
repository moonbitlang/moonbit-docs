pub fn f(x: Int, y: Int) -> Unit {
  for i = 0; i < x; i = i + 1 {
    for j = { break }; j < y; j = j + 1 {
//            ^^^^^ Error: The usage of break statement is invalid.
        println(i + j)
    }
  }
}