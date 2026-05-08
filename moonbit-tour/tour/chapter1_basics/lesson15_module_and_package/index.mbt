///|
fn main {
  // use full path
  println(@moonbitlang/core/math.pow(2, 3))
  println(@moonbitlang/core/int.MAX_VALUE)

  // use shorter aliases
  println(@math.pow(2, 3))
  println(@int.MAX_VALUE)
}
