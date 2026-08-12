///|
pub fn consume(value? : Int) -> Unit {
  ignore(value)
}

///|
pub fn demo() -> Unit {
  consume(value?=Some(42))
}
