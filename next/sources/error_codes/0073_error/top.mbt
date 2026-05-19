///|
priv struct Point {
  x : Int
}

///|
fn make_point() -> Point {
  Point::{ x: 1 }
}

///|
test {
  inspect(make_point().x, content="1")
}
