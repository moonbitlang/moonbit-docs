///|
fn f(opt~ : Int) -> Unit {
  println("opt: \{opt}")
}

///|
fn main {
  let opt = Some(42)
  // Error: This form of application is invalid for argument opt~, because it is not declared with opt? : _.
  f(opt?)
}
