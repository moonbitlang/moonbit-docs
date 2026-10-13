///|
pub fn f(x : Int32, y : Int32) -> Unit {
  for i = 0; i < x; i = i + 1 {
    for j = ({
            continue
          })
        j < y
        j = j + 1 {
      //            ^^^^^^^^ Error: The usage of continue statement is invalid.
      println(i + j)
    }
  }
}
