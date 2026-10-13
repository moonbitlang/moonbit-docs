///|
pub fn f1() -> Unit {
  fn f(x : Int32?) {
    match x {
      None => ()
      Some(a) => println(a)
    }
  }

  f(None)
}

///|
pub fn f2() -> Unit {
  fn f(x : Array[Int32]) -> Int32 {
    x.length()
  }

  println(f([]))
}
