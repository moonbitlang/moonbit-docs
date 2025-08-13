pub fn f1() -> Unit {
  fn f(x) {
    match x {
      None => ()
      Some(a) => println(a + 1)
//                       ^^^^^ through this usage, the compiler can infer the
//                             type of `x` is `Option[Int]`.
    }
  }
  f(None)
}
