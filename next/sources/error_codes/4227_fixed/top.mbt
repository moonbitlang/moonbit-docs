///|
async fn noncancellable_operation() -> Unit nocancel {
  ()
}

///|
pub async fn run_without_cancellation() -> Unit nocancel {
  noncancellable_operation()
}
