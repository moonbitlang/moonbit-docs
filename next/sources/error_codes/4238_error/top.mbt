///|
#non_exhaustive
pub(all) suberror ParseError {
  InvalidInput
}

///|
pub fn is_parse_error(error : Error) -> Bool {
  match error {
    ParseError::InvalidInput => true
    ParseError::.. => true
    _ => false
  }
}
