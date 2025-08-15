///|
fn f() -> Int {
  let opt = 4
  ignore(opt)
  0
}

///|
fn main {
  println(f())
  println(f())
}
