///|
pub struct T {
  mut value : Int32
}

///|
pub fn T::new() -> T {
  T::{ value: 0 }
}

///|
pub fn T::set(self : T, value : Int32) -> Unit {
  self.value = value
}
