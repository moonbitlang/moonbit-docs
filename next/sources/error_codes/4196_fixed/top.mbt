///|
fn keep(
  x : Int32,
) -> Int32 where {
  proof_ensure: result => result == x,
  proof_reasoning: "The function returns its argument unchanged.",
} {
  x
}

///|
test {
  inspect(keep(2), content="2")
}
