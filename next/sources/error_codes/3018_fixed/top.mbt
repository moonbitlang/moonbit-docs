///|
const A = 3

///|
fn describe(value : Int) -> String {
  match value {
    0..<A => "between"
    _ => "outside"
  }
}

///|
test {
  inspect(describe(0), content="between")
}
