///|
pub(all) struct Point {
  x : Int
}

///|
fn make_point(x : Int) -> Point {
  { x, }
}

///|
test {
  let point = make_point(1)
  inspect(point.x, content="1")
}
