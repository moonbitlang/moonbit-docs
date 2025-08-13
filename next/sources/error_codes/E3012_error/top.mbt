struct S {
  value : Int
}

pub fn S::op_get(self : S, index : String) -> Int? {
  if index == "value" {
    return Some(self.value)
  }
  return None
}

fn main {
  let s : S = { value: 42 }
  match s {
    { "value": value, value } => println("Value is: \{value}") // Error: Struct pattern and map pattern cannot be mixed.
    _ => println("No value")
  }
}