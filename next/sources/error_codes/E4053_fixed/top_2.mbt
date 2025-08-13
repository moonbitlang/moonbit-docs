trait A: Default {
  f(Self) -> Int
}

impl A with f(self : Self) -> Int {
  ignore(self)
  0
}