struct Point {
  x : Double
  y : Double
}

fn main {
  let point = Point::{ x : 1.0, y : 2.0 }
  println(point.x)
  println(point.y)
}