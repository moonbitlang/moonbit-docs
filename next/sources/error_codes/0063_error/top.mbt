///|
pub fn consume(value? : Int32) -> Unit {
  ignore(value)
}

///|
pub fn demo() -> Unit {
  consume(value?=Some(42))
}
