///|
struct Point {
  x : Int32
  y : Int32
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
