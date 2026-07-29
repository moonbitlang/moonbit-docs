///|
pub fn skip_all() -> Unit {
  outer~: for i = 0; i < 3; i = i + 1 {
    ignore(i)
    continue outer~
  }
}
