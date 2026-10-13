///|
fn f(opt? : Int32 = 4) -> Int32 {
  ignore(opt)
  0
}

///|
fn main {
  println(f())
  println(f())
}
