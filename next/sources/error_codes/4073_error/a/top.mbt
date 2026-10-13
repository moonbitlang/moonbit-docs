// We need the trait to be pub(open) so that it can be implemented from outside.
pub(open) trait T {
  f(Self) -> Int32 = _
}

impl T with f(self : Self) -> Int32 {
  ignore(self)
  0
}
