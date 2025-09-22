///|
fn main {
  // explicit type annotation
  let a1 : Int = 10
  println((10 : Int))

  // Variable with type inference (Int inferred from value 20)
  let b = 20
  println("a + b = \{a1 + b}")

  // Mutable variable - can be modified
  let mut c = 10
  println("c before: \{c}")
  c = c + 1
  println("c after: \{c}")

  // Immutable variable - cannot be modified
  let d = 20
  println("d = \{d}")
  // d = d + 1  // Uncommenting this line will cause a compilation error
}
