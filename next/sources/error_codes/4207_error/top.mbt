///|
fn invalid_predicate() -> Unit {
  let _ = ∀ i : Int32, 0 <= i
}

///|
test {
  ignore(invalid_predicate)
}
