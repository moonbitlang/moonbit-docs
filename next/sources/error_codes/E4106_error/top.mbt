pub fn f(x: Int) -> Unit {
  let mut j = 0
  for i = 0; i < x; i = i + 1, j = j + 1 {
//                             ^ --- Error: Unknown binder j in the for-loop
//                                          steps. Binders in the steps must be
//                                          declared in the initialization
//                                          block of the for-loop.
    println(i)
    println(j)
  }
}