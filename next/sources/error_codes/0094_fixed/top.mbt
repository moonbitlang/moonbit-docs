///|
pub fn add_one(value : Int32) -> Int32 {
  value + 1
}

///|
test {
  assert_eq(add_one(41), 42)
}
