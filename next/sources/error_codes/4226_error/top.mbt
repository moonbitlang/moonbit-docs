///|
priv suberror ParseError {
  InvalidSyntax
}

///|
pub fn is_parse_error(error : ParseError) -> Bool {
  match error {
    ParseError::_ => true
  }
}
