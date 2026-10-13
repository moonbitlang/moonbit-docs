priv trait I {
  m(Self) -> Unit
}

pub impl I for Int32 with m(self) {
  ignore(self)
}
