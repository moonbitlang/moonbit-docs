///|
const A = 3

///|
fn describe(value : Int32) -> String {
  match value {
    0..<A => "between"
    _ => "outside"
  }
}

///|
test {
  inspect(describe(0), content="between")
}
