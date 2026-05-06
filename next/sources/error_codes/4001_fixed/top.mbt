///|
priv struct S {
  field : Int
}

///|
pub fn get_field() -> Int {
  S::{ field: 0 }.field
}
