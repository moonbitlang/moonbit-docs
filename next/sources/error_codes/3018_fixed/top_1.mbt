///|
fn describe_literal(value : Int32) -> String {
  match value {
    0..<3 => "between"
    _ => "outside"
  }
}

///|
test {
  inspect(describe_literal(0), content="between")
}
