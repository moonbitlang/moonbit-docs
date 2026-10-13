///|
fn describe(value : Int32) -> String {
  match value {
    0..<=_ => "non-negative"
    _ => "negative"
  }
}

///|
test {
  inspect(describe(0), content="non-negative")
}
