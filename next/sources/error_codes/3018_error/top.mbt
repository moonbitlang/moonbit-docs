///|
fn describe(value : Int32, limit : Int32) -> String {
  match value {
    0..<limit => "between"
    _ => "outside"
  }
}

///|
test {
  inspect(describe(0, 3), content="between")
}
