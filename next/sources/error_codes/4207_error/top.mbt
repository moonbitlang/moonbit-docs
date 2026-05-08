///|
fn invalid_predicate() -> Unit {
  let _ = ∀ i : Int, 0 <= i
}

///|
test {
  ignore(invalid_predicate)
}
