///|
pub fn next_token(lexbuf : @lexbuf.Lexbuf) -> String {
  lexscan lexbuf {
    (re"^[a-z]+" as word) => word.to_owned()
    rest => rest.to_owned()
  }
}
