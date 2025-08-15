///|
fn f(xss : Array[Array[Int]]) -> Unit {
  l~: for xs in xss {
    // Warning: The label name `l` shadows a label name that is already in scope.
    l~: for x in xs {
      if x > 0 {
        break l~
      }
    }
  }
}
