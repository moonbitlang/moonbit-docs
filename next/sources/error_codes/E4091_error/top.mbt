struct Point {
  x : Double
  y : Double
}

fn main {
  let point = Point::{ x : 1.0, y : 2.0 }
  println(point.z) // Error: The type Point has no field z.
}