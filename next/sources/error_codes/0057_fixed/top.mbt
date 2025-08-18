///|
pub fn[T] is_some(s : T?) -> Bool {
  match s {
    Some(_) => true
    None => false
  }
}
