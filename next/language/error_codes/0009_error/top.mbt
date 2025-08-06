///|
pub struct A { // Warning: the struct A is never constructed
  value : Int
}

///|
priv struct B { // Warning: the struct B is never constructed
  value : Int
}

///|
fn B::get(a : B) -> Int {
  a.value
}
