///|
fn f(opt? : Int32) -> Unit {
  let opt = match opt {
    Some(opt) => opt
    None => 4
  }
  println("opt: \{opt}")
}
