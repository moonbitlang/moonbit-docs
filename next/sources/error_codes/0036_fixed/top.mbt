///|
fn f(xss : Array[Array[Int]]) -> Unit {
  outer~: for xs in xss {
    inner~: for x in xs {
      if x > 0 {
        break inner~
      }
    }
  }
}
