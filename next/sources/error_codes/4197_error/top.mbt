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
  match point {
    Point(x) => x
  }
}

///|
test {
  let _ = read(Point(1))
}
