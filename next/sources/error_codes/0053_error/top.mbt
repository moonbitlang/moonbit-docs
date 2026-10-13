///|
trait Any {}

///|
pub fn[T : Any] check(_ : T) -> Unit {
  println("Hello")
}

///|
pub fn[T : Compare] shortlex(a : Array[T], b : Array[T]) -> Int32 {
  Int32::compare(a.length(), b.length())
}
