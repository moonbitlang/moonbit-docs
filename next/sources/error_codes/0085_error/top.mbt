///|
pub fn stop_immediately() -> Unit {
  outer~: for i = 0; i < 3; i = i + 1 {
    ignore(i)
    break
  }
}
