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
  match point {
    Point(x) => x
  }
}

///|
test {
  let _ = read(Point(1))
}
