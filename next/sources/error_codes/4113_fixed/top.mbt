///|
pub enum E {
  A(a~ : Int32, b~ : Bool)
}

///|
pub fn f(x : E) -> Unit {
  match x {
    A(..) as a => {
      println(a.a)
      println(a.b)
    }
  }
}

///|
test {
  f(A(a=1, b=true))
}
