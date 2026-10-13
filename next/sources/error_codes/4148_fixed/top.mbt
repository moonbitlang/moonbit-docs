pub fn skip_zero(values : Array[Int32]) -> Unit {
  outer~: for value in values {
    if value == 0 {
      continue outer~
    }
    println(value)
  }
}
