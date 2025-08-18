///|
struct Point {
  x : Int
  y : Int
}

///|
pub fn quadrant(p : Point) -> String {
  match p {
    { x: _..<0, .. } => "Third or Fourth Quadrant"
    { x: 0..<_, y: 0..<_ } => "First Quadrant"
    { x: 0..<_, y: _..<0 } => "Second Quadrant"
  }
}
