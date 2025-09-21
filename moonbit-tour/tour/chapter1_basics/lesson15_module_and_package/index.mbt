///|
fn main {
  // use full path
  println(@moonbitlang/core/math.pow(2, 3))
  println(@moonbitlang/core/int.max_value)

  // use shorter aliases
  println(@math.pow(2, 3))
  println(@int.max_value)
}
