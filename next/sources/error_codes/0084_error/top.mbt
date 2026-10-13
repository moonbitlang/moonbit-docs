///|
pub struct Point {
  x : Int32
  y : Int32
}

///|
pub fn origin() -> Point {
  let point : Point = { x: 0, y: 0 }
  point
}
