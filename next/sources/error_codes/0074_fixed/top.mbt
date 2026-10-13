/// Returns a stable value for the example.
pub fn exposed() -> Int32 {
  1
}

///|
test {
  inspect(exposed(), content="1")
}
