///|
fn f(a : Int32?, b : Int32?) -> Unit {
  match (a, b) {
    (Some(a), Some(a)) => println("Some(\{a})")
    _ => println("None")
  }
}
