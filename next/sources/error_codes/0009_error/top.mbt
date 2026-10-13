///|
pub struct A { // Warning: the struct A is never constructed
  value : Int32
}

///|
priv struct B { // Warning: the struct B is never constructed
  value : Int32
}

///|
fn B::get(a : B) -> Int32 {
  a.value
}
