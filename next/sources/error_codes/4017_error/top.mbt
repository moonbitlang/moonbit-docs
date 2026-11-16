///|
pub(open) trait A {
  fn value(Self) -> Int32
}

///|
pub(open) trait B {
  fn value(Self) -> Int32
}

///|
pub fn[T : A + B] read(x : T) -> Int32 {
  x.value()
}
