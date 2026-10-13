///|
pub(all) suberror ParseError {
  ParseError
}

///|
pub fn parse_number() -> Result[Int32, ParseError] {
  Err(ParseError)
}
