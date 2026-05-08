///|
pub struct T(Int)

///|
pub fn make(x : Int) -> T {
  T(x)
}

///|
fn T::m(self : T, x : Int) -> Unit {
  println(self.0 + x)
}

///|
pub fn f(t : T, x : Int) -> Unit {
  (fn(x : Int) { println(x) })(x)
  t.m(x)
}
