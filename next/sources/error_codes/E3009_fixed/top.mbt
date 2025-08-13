struct Point {
  x: Int
  y: Int
}

fn process_point(p: Point) -> Unit {
  match p {
    _ => println("Got a point")
  }
}