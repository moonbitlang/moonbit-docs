///|
fn f(a : Int32?, b : Int32?) -> Unit {
  match (a, b) {
    (Some(a), Some(b)) => println("Some(\{a}), Some(\{b})")
    _ => println("None")
  }
}

///|
test {
  f(Some(1), Some(2))
}
