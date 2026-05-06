pub fn use_helpers() -> Unit {
  fn helper1() {
    1 + 1
  }

  fn helper2() {
    2 + 2
  }

  ignore(helper1())
  ignore(helper2())
}
