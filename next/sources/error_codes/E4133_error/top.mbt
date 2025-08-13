fn main {
  for a, b, c in [1, 2, 3] { // Error: This `for .. in` loop has 3 loop variables, but at most 2 is expected.
    ...
  }
}