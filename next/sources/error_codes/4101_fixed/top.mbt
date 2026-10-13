///|
pub struct T(Int32)

///|
pub fn make(x : Int32) -> T {
  T(x)
}

///|
fn T::m(self : T, x : Int32) -> Unit {
  println(self.0 + x)
}

///|
pub fn f(t : T, x : Int32) -> Unit {
  (fn(x : Int32) { println(x) })(x)
  t.m(x)
}
