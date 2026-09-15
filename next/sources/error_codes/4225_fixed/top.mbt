///|
priv suberror StatusError {
  NotReady
  Busy
}

///|
pub fn is_status_error(error : Error) -> Bool {
  match error {
    StatusError::_ => true
    _ => false
  }
}
