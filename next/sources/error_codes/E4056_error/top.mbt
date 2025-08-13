struct Point {
  x: Int
  y: Int
}

fn Point::to_string(self : Point) -> String {
  "(" + self.x.to_string() + "," + self.y.to_string() + ")"
}

fn Point::to_string(self : Point) -> String {
  "<" + self.x.to_string() + "," + self.y.to_string() + ">"
}