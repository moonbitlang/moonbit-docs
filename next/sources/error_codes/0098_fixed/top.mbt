///|
pub async fn operation() -> Unit {
  defer @async.protect_from_cancel(() => @async.sleep(1))
  @async.sleep(1)
}
