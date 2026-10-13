///|
fn has_positive(xs : Array[Int32]) -> Bool {
  found~: {
    search~: for x in xs {
      if x > 0 {
        break found~ true
      }
      continue search~
    }
    false
  }
}
