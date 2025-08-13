enum Point {
  D2(Double, Double)
  D3(Double, Double, Double)
}

fn main {
  let a = Point::{ x : 1.0, y : 2.0 }
  //      ^~~~~
  // Error: The type Point is not a struct type
}