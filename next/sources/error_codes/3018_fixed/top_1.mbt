///|
fn describe_literal(value : Int) -> String {
  match value {
    0..<3 => "between"
    _ => "outside"
  }
}

///|
test {
  inspect(describe_literal(0), content="between")
}
