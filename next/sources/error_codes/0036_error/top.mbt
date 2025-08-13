fn f(xss : Array[Array[Int]]) -> Unit {
  l~: for xs in xss {
    l~: for x in xs {
//  ^^  Warning: The label name `l` shadows a label name that is already in
//               scope.
      if x > 0 {
        break l~
      }
    }
  }
}
