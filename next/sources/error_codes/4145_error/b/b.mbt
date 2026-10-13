pub struct A {
  value : Int32
}

impl @a.Sealed for A with to_int(self : A) -> Int32 { // Error: Cannot implement trait '@a.Sealed' because it is readonly.
  self.value
}

pub fn make(value : Int32) -> A {
  { value, }
}
