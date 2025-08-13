type! StringError String

pub fn may_raise_error() -> Unit!StringError {
  raise StringError("Failed")
}