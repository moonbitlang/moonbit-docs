///|
trait Number {
  to_int(Self) -> Int32
  to_float(Self) -> Float
}

///|
struct A(Int32)

///|
impl Number for A with to_int(self : A) -> Int32 {
  //^~~~~~~~~~~~~~~
  // Error: Type A does not implement trait Number, although an `impl` is defined.
  // hint:
  //   method to_float is missing.
  self.0
}
