///|
priv suberror ParseError {
  InvalidSyntax
}

///|
pub fn is_parse_error(error : Error) -> Bool {
  match error {
    ParseError::_ => true
    _ => false
  }
}
