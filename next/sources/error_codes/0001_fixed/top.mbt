// make public

///|
pub fn greeting() -> String {
  "Hello!"
}
// end make public

// ignore unused

///| 
fn unused() -> String {
  "Hello, world!"
}

///|
test {
  ignore(unused)
}

///|
test {
  fn local_greeting() -> String {
    "Hello, world!"
  }

  ignore(local_greeting)
}
// end ignore unused
