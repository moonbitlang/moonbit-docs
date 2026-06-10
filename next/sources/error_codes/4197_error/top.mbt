///|
priv struct Point {
  x : Int
}

///|
fn Point::Point(x : Int) -> Point {
  { x, }
}

///|
fn read(point : Point) -> Int {
  match point {
    Point(x) => x
  }
}

///|
test {
  let _ = read(Point(1))
}
