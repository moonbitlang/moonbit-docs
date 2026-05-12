fn init {
  let x = 42
  fn f(g) {
    g(x~)
  //^
  // Error: This function is not a toplevel function, so it cannot have labelled arguments.
  }
  f(h)
}

fn h(x : Int) -> Unit {
  ignore(x)
}
