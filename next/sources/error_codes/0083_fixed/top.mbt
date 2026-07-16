///|
pub(open) trait Position {
  fn pos(Self) -> (Int, Int)
}

///|
pub(open) trait Object: Position {}

///|
pub fn[O : Object] position_of(object : O) -> (Int, Int) {
  Position::pos(object)
}
