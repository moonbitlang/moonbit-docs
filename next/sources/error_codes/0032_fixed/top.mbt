///|
fn f(opt~ : Int32) -> Int32 {
  ignore(opt)
  0
}

///|
fn main {
  println(f(opt=3))
  println(f(opt=3))
}
