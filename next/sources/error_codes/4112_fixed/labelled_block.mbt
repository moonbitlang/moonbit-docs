///|
pub fn skip_block() -> Unit {
  block~: {
    break block~
  }
}
