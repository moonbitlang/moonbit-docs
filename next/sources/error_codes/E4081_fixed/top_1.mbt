fn f(a : Int?, b : Int?) -> Unit {
  match (a, b) {
    (Some(_), Some(a)) => println("Some(\{a})")
    _ => println("None")
  }
}