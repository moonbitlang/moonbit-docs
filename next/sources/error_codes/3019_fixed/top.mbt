///|
fn describe(value : Int) -> String {
  match value {
    0..<_ => "non-negative"
    _ => "negative"
  }
}

///|
test {
  inspect(describe(0), content="non-negative")
}
