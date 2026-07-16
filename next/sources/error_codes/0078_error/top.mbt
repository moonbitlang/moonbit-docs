///|
pub(all) suberror ParseError {
  ParseError
}

///|
pub fn parse_number() -> Result[Int, ParseError] {
  Err(ParseError)
}
