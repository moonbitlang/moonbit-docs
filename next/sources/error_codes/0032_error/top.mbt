///|
fn f(opt~ : Int = 4) -> Int {
  ignore(opt)
  0
}

///|
fn main {
  println(f(opt=3))
  println(f(opt=3))
}
