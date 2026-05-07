///|
priv struct Point {
  x : Int

  fn new(Int) -> Point
}

///|
fn Point::new(text : String) -> Point {
  { x: text.length() }
}
