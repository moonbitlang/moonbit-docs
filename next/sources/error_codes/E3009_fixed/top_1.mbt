fn process_point(p: Point) -> Unit {
  match p {
    { x: 0, .. } => println("Point on y-axis")
    _ => println("Other point")
  }
}