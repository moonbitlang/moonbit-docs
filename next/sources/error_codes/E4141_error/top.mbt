fn f(opt~ : Int = 4) -> Unit {
  println("opt: \{opt}")
}

fn main {
  let opt = Some(42)
  f(opt?) // Error: This form of application is invalid for argument opt~, because it is not declared with opt? : _.
}