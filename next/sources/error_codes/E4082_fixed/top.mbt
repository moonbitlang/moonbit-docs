fn f(value : E) -> Unit {
  match value {
    A(a, _) | B(a) => println("Hello")
  }
}