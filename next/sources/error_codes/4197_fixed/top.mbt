///|
priv struct Point {
  x : Int32
}

///|
fn Point::Point(x : Int32) -> Point {
  { x, }
}

///|
fn read(point : Point) -> Int32 {
  point.x
}

///|
test {
  inspect(read(Point(3)), content="3")
}
