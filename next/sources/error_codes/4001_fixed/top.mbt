///|
priv struct S {
  field : Int32
}

///|
pub fn get_field() -> Int32 {
  S::{ field: 0 }.field
}
