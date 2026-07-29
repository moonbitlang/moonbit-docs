///|
pub struct Point {
  x : Int
  y : Int
}

///|
pub fn origin() -> Point {
  let point : Point = { x: 0, y: 0 }
  point
}
