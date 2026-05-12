pub suberror StringError {
  StringError(String)
}

pub fn may_raise_error() -> Unit raise StringError {
  raise StringError("Failed")
}
