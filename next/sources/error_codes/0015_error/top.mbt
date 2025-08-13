fn main {
  let mut x = [1, 2, 3] // Warning: The mutability of 'x' is never used.
  x[0] = 0
  println(x)
}
