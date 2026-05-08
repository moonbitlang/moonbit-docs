///|
fn g(a : Int?, b : Int?) -> Unit {
  match (a, b) {
    (Some(_), Some(a)) => println("Some(\{a})")
    _ => println("None")
  }
}

///|
test {
  g(Some(1), Some(2))
}
