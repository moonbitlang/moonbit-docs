pub(open) trait T {
  f(Self) -> Int32 = _
}

impl T with f(self : Self) -> Int32 {
  ignore(self)
  0
}
