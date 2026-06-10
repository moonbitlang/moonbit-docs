///|
priv struct Point {
  x : Int
}

///|
fn Point::Point(x : Int) -> Point {
  { x, }
}

///|
test {
  let point = Point(1)
  inspect(point.x, content="1")
}
