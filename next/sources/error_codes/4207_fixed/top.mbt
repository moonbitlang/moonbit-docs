///|
fn checked_predicate() -> Unit {
  proof_assert ∀ i : Int, i == i
}

///|
test {
  checked_predicate()
}
