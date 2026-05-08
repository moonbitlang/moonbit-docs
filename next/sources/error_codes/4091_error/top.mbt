///|
priv struct Point {
  x : Double
  y : Double
}

///|
test {
  let point = Point::{ x: 1.0, y: 2.0 }
  inspect(point.z) // Error: The type Point has no field z.
}
