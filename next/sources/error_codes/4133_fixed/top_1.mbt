pub fn iterate_tuples() -> Unit {
  for v in [(1, 2, 3), (4, 5, 6)] {
    let (a, b, c) = v
    println("\{a}, \{b}, \{c}")
  }
}
