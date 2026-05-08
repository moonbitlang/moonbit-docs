///|
pub enum Err {
  IntErr(Int)
}

///|
fn square(x : Int) -> Int {
  x * x
}

///|
pub fn invalid_attribute() -> Unit {
  square!!(1) |> ignore()
  // Error: The attribute `!!` cannot be used on application that does not raise
  // errors.
}
