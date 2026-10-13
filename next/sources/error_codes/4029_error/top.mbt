pub(all) struct T {
  value : Int32
}

pub fn check(value : Int32?) -> Int32 {
  match value {
    T::None => 0
    Some(value) => value
  }
}
