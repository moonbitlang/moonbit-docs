trait Number {
  to_int(Self) -> Int
  to_float(Self) -> Float
}

type A Int

impl Number for A with to_int(self : A) -> Int {
//^~~~~~~~~~~~~~~
// Error: Type A does not implement trait Number, although an `impl` is defined.
// hint:
//   method to_float is missing.
  self.inner()
}