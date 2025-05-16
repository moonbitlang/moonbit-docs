fn main {
  let (a, (b, _) as tuple, _) as triple = (1, (true, 5), false)
  println("a: \{a}, b: \{b}")
  println("tuple: \{tuple}")
  println("triple: \{triple}")
}
