///|
pub enum Err {
  IntErr(Int)
}

///|
fn square(x : Int) -> Int {
  x * x
}

///|
pub fn constructor_value() -> Err {
  IntErr(1)
}

///|
pub fn square_value() -> Int {
  square(2)
}
