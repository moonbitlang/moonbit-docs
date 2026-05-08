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
  x |> t.m()
  //     ^^^^ Error: Unsupported expression after the pipe operator.
}
