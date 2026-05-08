struct Point {
  x : Int
  y : Int
} derive(Debug)

fn main {
  // create a point
  let point = { x: 3, y: 4 }
  println("point: \{to_repr(point)}")
  println("point.x: \{point.x}")
  println("point.y: \{point.y}")
  
  // functional update
  let point2 = {..point, x: 20}
  println("update: \{to_repr(point2)}")
}
