/// Returns a stable value for the example.
pub fn exposed() -> Int {
  1
}

///|
test {
  inspect(exposed(), content="1")
}
