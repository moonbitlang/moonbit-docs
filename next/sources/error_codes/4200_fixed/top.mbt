///|
priv struct Point {
  x : Int32
}

///|
fn Point::Point(x : Int32) -> Point {
  { x, }
}

///|
test {
  let point = Point(1)
  inspect(point.x, content="1")
}
