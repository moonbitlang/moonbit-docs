///|
fn keep(x : Int) -> Int where { proof_note: x >= 0 } {
  x
}

///|
test {
  ignore(keep)
}
