pub(open) trait T {
  f(Self) -> Int = _
}

impl T with f(self : Self) -> Int {
  ignore(self)
  0
}
