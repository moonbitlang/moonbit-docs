///|
pub(all) struct S {
  value : Int32
}

///|
pub fn S::get(self : S, index : String) -> Int32? {
  if index == "value" {
    return Some(self.value)
  }
  return None
}

///|
fn use_map_pattern(s : S) -> Unit {
  match s {
    { "value": value, .. } => println("Value is: \{value}")
    _ => println("No value")
  }
}

///|
test {
  let s : S = { value: 42 }
  use_map_pattern(s)
  use_struct_pattern(s)
}
