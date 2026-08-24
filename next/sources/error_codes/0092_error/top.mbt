///|
fn operation_that_may_fail() -> Unit raise {
  fail("operation failed")
}

///|
pub fn run() -> Unit raise {
  try operation_that_may_fail() catch {
    error => {
      println("cleanup")
      raise error
    }
  }
}
