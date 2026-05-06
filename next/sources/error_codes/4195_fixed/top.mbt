///|
fn keep(
  x : Int,
) -> Int where {
  proof_require: x >= 0,
  proof_ensure: result => result == x,
  proof_reasoning: "The function returns its argument unchanged.",
} {
  x
}

///|
test {
  inspect(keep(1), content="1")
}
