pub(open) trait I {
  m(Self) -> Unit
}

pub impl I for Int32 with m(self) {
  ignore(self)
}

pub fn call_i(x : Int32) -> Unit {
  I::m(x)
}
