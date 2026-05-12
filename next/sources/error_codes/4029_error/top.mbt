pub(all) struct T {
  value : Int
}

pub fn check(value : Int?) -> Int {
  match value {
    T::None => 0
    Some(value) => value
  }
}
