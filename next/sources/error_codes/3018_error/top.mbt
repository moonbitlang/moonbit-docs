///|
fn describe(value : Int, limit : Int) -> String {
  match value {
    0..<limit => "between"
    _ => "outside"
  }
}

///|
test {
  inspect(describe(0, 3), content="between")
}
