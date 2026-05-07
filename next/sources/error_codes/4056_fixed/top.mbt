///|
priv struct Point {
  x : Int
  y : Int
}

///|
fn Point::to_string(self : Point) -> String {
  "(" + self.x.to_string() + "," + self.y.to_string() + ")"
}

///|
test {
  let point : Point = { x: 1, y: 2 }
  inspect(point.to_string(), content="(1,2)")
}
