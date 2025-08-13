pub struct T {
  mut value : Int
}

pub fn T::new() -> T {
  T::{ value: 0 }
}

pub fn T::set(self : T, value : Int) -> Unit {
  self.value = value
}