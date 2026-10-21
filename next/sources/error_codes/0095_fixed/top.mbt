///|
pub fn describe(value : Double) -> String {
  match value {
    x if x.is_nan() => "not a number"
    _ => "number"
  }
}

///|
test {
  inspect(describe(0.0 / 0.0), content="not a number")
  inspect(describe(1.0), content="number")
}
