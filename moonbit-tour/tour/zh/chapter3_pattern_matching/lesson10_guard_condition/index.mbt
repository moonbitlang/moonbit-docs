///|
fn validate(path : String?) -> Bool {
  match path {
    Some(path) if path != "" => true
    _ => false
  }
}

///|
fn main {
  let path1 = Some("/home/config")
  let path2 = Some("")
  let path3 = None
  println(validate(path1))
  println(validate(path2))
  println(validate(path3))
}
