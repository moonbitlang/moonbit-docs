///|
trait Any {}

// start example 0

///|
pub fn[T] check(_ : T) -> Unit {
  println("Hello")
}

// start example 1

///|
pub fn[T : Any] check_any(t : T) -> Unit {
  let _ = t as &Any
  println("Hello")
}

// start example 2

///|
pub fn[T : Compare] shortlex(a : Array[T], b : Array[T]) -> Int {
  match Int::compare(a.length(), b.length()) {
    _..<0 => -1
    1..<_ => 1
    0 =>
      for i = 0; i < a.length(); i = i + 1 {
        match T::compare(a[i], b[i]) {
          _..<0 => return -1
          1..<_ => return 1
          0 => ()
        }
      } else {
        return 0
      }
  }
}
