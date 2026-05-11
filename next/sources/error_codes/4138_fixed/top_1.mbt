pub fn print_range() -> Unit {
  let range : Iter[Int] = (0).until(10)
  for i in range {
    println(Float::from_int(i))
  }
}
