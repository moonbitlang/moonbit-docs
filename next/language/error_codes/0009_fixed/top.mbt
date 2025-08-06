// use pub(all)

///|
pub(all) struct A {
  value : Int
}
// end use pub(all)

// smart constructor

///|
priv struct B {
  value : Int
}

///|
fn B::new(value : Int) -> B {
  B::{ value, }
}
// end smart constructor

///|
fn B::value(self : B) -> Int {
  self.value
}

///|
test {
  ignore(B::value(B::new(10)))
}
