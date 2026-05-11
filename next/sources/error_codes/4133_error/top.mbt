pub fn bad_loop() -> Unit {
  for a, b, c in [1, 2, 3] { // Error: This `for .. in` loop has 3 loop variables, but at most 2 is expected.
    println("\{a}, \{b}, \{c}")
  }
}
