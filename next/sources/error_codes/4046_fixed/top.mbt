pub(open) trait I {
  m(Self) -> Unit
}

pub impl I for Int with m(self) {
  ignore(self)
}

pub fn call_i(x : Int) -> Unit {
  I::m(x)
}
