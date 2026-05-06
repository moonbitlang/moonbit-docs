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
fn read(point : Point) -> Int {
  point.x
}

///|
test {
  inspect(read(Point(3)), content="3")
}
