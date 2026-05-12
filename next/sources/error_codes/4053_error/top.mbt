pub(open) trait T {
  f(Self) -> Unit
}

impl T for (Int) -> Unit with f(self) {
  //                         ^
  // Error: Invalid type for "self": must be a type constructor.
  self(0)
}
