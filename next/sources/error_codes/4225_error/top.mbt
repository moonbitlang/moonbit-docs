///|
enum Status {
  Ready
  Busy
}

///|
pub fn is_status(error : Error) -> Bool {
  match error {
    Status::_ => true
    _ => false
  }
}
