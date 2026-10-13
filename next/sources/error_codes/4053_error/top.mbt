pub(open) trait T {
  f(Self) -> Unit
}

impl T for (Int32) -> Unit with f(self) {
  //                         ^
  // Error: Invalid type for "self": must be a type constructor.
  self(0)
}
