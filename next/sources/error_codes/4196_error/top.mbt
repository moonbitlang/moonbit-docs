///|
fn keep(
  x : Int,
) -> Int where {
  proof_ensure: result => result == x,
  proof_reasoning: x,
} {
  x
}

///|
test {
  ignore(keep)
}
