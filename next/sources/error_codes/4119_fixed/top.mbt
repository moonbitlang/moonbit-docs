fn init {
  let x = 42
  fn f(g) {
    g(x)
  }
  f(h)
}

fn h(x : Int) -> Unit {
  ignore(x)
}
