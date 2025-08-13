pub fn f(x: Int, y: Int) -> Unit {
  for i = 0; i < x; i = i + 1 {
    for j = { continue }; j < y; j = j + 1 {
//            ^^^^^^^^ Error: The usage of continue statement is invalid.
        println(i + j)
    }
  }
}