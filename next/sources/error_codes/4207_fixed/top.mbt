///|
fn checked_predicate() -> Unit {
  proof_assert ∀ i : Int32, i == i
}

///|
test {
  checked_predicate()
}
