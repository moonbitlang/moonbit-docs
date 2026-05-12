pub fn use_legacy_helper() -> Unit {
  fn legacy_helper() {
    1 + 1
  }

  fn legacy_helper() {
    2 + 2
  }

  ignore(legacy_helper())
}
