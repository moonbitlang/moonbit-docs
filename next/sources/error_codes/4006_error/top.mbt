pub fn use_helper() -> Unit {
  fn helper() {
    1 + 1
  }

  fn helper() {
    2 + 2
  }

  ignore(helper())
}
