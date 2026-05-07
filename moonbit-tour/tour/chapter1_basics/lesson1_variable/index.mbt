///|
fn main {
  // explicit type annotation
  let a : Int = 10
  println((10 : Int))

  // Variable with type inference (Int inferred from value 20)
  let b = 20
  println(a + b)

  // Mutable variable - can be modified
  let mut c = 10
  c = c + 1
  println(c)

  // Immutable variable - cannot be modified
  let d = 20
  println(d)
  // d = d + 1  // Uncommenting this line will cause a compilation error

  {
    let e = 100
    println(e)
  }
  // println(e) // Uncommenting this line will cause a compilation error

  // access top-level variable
  println(f)
}

///|
/// define a variable in top-level scope
let f : Double = 3.14

