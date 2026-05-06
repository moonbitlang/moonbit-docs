///|
priv struct Point {
  x : Int

  fn new(Int) -> Point
}

///|
fn Point::new(x : Int) -> Point {
  { x, }
}

///|
test {
  let point = Point(4)
  inspect(point.x, content="4")
}
