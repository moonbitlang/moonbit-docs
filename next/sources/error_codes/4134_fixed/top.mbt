///|
pub fn print_values(values : Array[Option[Int32]]) -> Unit {
  for value in values {
    match value {
      Some(value) => println(value)
      None => ()
    }
  }
}
