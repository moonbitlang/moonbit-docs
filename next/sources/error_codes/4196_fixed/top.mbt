///|
fn keep(
  x : Int,
) -> Int where {
  proof_ensure: result => result == x,
  proof_reasoning: "The function returns its argument unchanged.",
} {
  x
}

///|
test {
  inspect(keep(2), content="2")
}
