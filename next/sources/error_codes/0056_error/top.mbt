///|
struct Point {
  x : Int32
  y : Int32
}

///|
pub fn quadrant(p : Point) -> String {
  match p {
    { x: _..<0 } => "Third or Fourth Quadrant"
    { x: 0..<_ } => "First or Second Quadrant"
  }
}
