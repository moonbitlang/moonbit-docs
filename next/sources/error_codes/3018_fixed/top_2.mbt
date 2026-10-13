///|
fn describe_wildcard(value : Int32) -> String {
  match value {
    0..<_ => "non-negative"
    _ => "negative"
  }
}

///|
test {
  inspect(describe_wildcard(0), content="non-negative")
}
