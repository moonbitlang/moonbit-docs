fn f(a : Int?, b : Int?) -> Unit {
  match (a, b) {
    (Some(a), Some(b)) => println("Some(\{a}), Some(\{b})")
    _ => println("None")
  }
}