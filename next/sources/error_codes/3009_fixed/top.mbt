///|
pub(all) struct Point {
  x : Int
  y : Int
}

///|
fn process_point(p : Point) -> Unit {
  match p {
    _ => println("Got a point")
  }
}

///|
test {
  let p : Point = { x: 0, y: 1 }
  process_point(p)
  process_y_axis(p)
}
