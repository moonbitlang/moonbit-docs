///|
priv struct S {
  value : Int32
}

///|
fn use_struct_pattern(s : S) -> Unit {
  match s {
    { value, } => println("Value is: \{value}")
  }
}

///|
test {
  use_struct_pattern({ value: 42, })
}
