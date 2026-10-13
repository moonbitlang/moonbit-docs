///|
pub(open) trait Position {
  fn pos(Self) -> (Int32, Int32)
}

///|
pub(open) trait Object: Position {}

///|
pub fn[O : Object] position_of(object : O) -> (Int32, Int32) {
  Position::pos(object)
}
