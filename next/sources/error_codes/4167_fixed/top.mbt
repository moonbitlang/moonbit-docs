///|
pub(open) trait HasDefaultImpl {
  foo() -> Unit = _
}

///|
impl HasDefaultImpl with foo() {
  println("OK")
}
