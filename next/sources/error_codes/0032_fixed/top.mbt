///|
fn f(opt~ : Int) -> Int {
  ignore(opt)
  0
}

///|
fn main {
  println(f(opt=3))
  println(f(opt=3))
}
