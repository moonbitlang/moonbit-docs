pub enum E {
  A(a~: Int)
}

pub fn f(x: E) -> Unit {
  match x {
    A(..) as a => {
      println(a.a)
      println(a.b)
//            ^^^ Error: Constructor A of type E has no field b.
    }
  }
}