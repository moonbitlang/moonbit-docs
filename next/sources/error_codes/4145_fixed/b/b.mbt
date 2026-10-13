pub struct A {
  value : Int32
}

impl @a.Sealed for A with to_int(self : A) -> Int32 {
  self.value
}

pub fn make(value : Int32) -> A {
  { value, }
}

pub fn value_of(a : A) -> Int32 {
  @a.Sealed::to_int(a)
}
