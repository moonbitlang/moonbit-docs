///|
fn keep(x : Int32) -> Int32 where { proof_note: x >= 0 } {
  x
}

///|
test {
  ignore(keep)
}
