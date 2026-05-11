pub fn skip_zero(values : Array[Int]) -> Unit {
  for value in values {
    if value == 0 {
      continue outer~
    //         ^~~~~
    // Error: The label outer is undeclared.
    }
    println(value)
  }
}
