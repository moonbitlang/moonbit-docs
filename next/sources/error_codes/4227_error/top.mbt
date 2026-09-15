///|
async fn cancellable_operation() -> Unit {
  ()
}

///|
pub async fn run_without_cancellation() -> Unit nocancel {
  cancellable_operation()
}
