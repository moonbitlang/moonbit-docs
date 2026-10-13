// use pub(all)

///|
pub(all) struct A {
  value : Int32
}
// end use pub(all)

// smart constructor

///|
priv struct B {
  value : Int32
}

///|
fn B::new(value : Int32) -> B {
  B::{ value, }
}
// end smart constructor

///|
fn B::value(self : B) -> Int32 {
  self.value
}

///|
test {
  ignore(B::value(B::new(10)))
}
