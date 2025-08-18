///|
fn f(opt? : Int) -> Unit {
  let opt = match opt {
    Some(opt) => opt
    None => 4
  }
  println("opt: \{opt}")
}
