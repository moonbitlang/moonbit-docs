///|
pub(open) trait HasDefaultImpl {
  foo() -> Unit // It has default implementation but is not marked
}

///|
impl HasDefaultImpl with foo() {
  println("OK")
}
