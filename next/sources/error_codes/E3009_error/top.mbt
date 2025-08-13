struct Point {
  x: Int
  y: Int
}

fn process_point(p: Point) -> Unit {
  match p {
    { .. } => println("Got a point")
  //^~~~~~
  // Error: Struct pattern cannot contain only `..`, use wildcard pattern `_` instead.
  }
}