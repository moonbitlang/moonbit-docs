///|
priv enum T {
  A
  B
  C
}

///|
pub fn f() -> Unit {
  match T::A {
    B => ()
    _ => ()
  }
}
