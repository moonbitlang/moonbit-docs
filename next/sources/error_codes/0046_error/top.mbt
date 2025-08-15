///|
struct Point {
  x : Int
  y : Int
}

///|
fn f(p : Point) -> Unit {
  let { x, y, .. } = p
  println(x + y)
}

///|
test {
  f({ x: 1, y: 2 })
}
