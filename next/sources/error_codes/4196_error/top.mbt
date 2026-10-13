///|
fn keep(
  x : Int32,
) -> Int32 where {
  proof_ensure: result => result == x,
  proof_reasoning: x,
} {
  x
}

///|
test {
  ignore(keep)
}
