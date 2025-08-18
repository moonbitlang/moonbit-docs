///|
trait Any {}

///|
pub fn[T : Any] check(_ : T) -> Unit {
  println("Hello")
}

///|
pub fn[T : Compare] shortlex(a : Array[T], b : Array[T]) -> Int {
  Int::compare(a.length(), b.length())
}
