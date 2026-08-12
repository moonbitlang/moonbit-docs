///|
fn has_positive(xs : Array[Int]) -> Bool {
  found~: {
    // Warning: The label name `found` shadows a label name that is already in scope.
    found~: for x in xs {
      if x > 0 {
        break found~
      }
    }
    false
  }
}
