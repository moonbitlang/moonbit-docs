pub struct A {
  value : Int
}

impl @a.Sealed for A with to_int(self : A) -> Int {
  self.value
}

pub fn make(value : Int) -> A {
  { value, }
}

pub fn value_of(a : A) -> Int {
  A::to_int(a)
}
