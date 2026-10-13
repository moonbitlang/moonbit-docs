///|
pub(all) struct Point {
  x : Int32
}

///|
fn make_point(x : Int32) -> Point {
  { x, }
}

///|
test {
  let point = make_point(1)
  inspect(point.x, content="1")
}
