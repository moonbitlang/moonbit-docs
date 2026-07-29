///|
pub fn skip_block() -> Unit {
  block~: {
    continue block~
  }
}
