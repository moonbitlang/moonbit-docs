fn main {
  let opt = Some(42)
  let opt = match opt {
    Some(opt) => opt
    None => 4
  }
  f(opt~)
}