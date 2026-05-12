// We need the trait to be pub(open) so that it can be implemented from outside.
pub(open) trait T {
  f(Self) -> Int = _
}

impl T with f(self : Self) -> Int {
  ignore(self)
  0
}
