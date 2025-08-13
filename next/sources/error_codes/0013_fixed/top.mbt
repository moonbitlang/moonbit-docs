pub fn f1() -> Unit {
  fn f(x: Option[Int]) {
    match x {
      None => ()
      Some(a) => println(a)
    }
  }
  f(None)
}

pub fn f2() -> Unit {
  fn f(x : Array[Int]) -> Int {
    x.length()
  }
  println(f([]))
}
