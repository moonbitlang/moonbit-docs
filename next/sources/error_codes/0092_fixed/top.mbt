///|
fn operation_that_may_fail() -> Unit raise {
  fail("operation failed")
}

///|
pub fn run() -> Unit raise {
  errdefer println("cleanup")
  operation_that_may_fail()
}
