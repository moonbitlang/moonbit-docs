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
  let point = Point(1)
  inspect(point.x, content="1")
}
