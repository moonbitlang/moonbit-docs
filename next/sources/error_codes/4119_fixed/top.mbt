fn init {
  let x = 42
  fn f(g) {
    g(x)
  }
  f(h)
}

fn h(x : Int32) -> Unit {
  ignore(x)
}
