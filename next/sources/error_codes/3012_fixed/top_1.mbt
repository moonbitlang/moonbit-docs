///|
fn use_struct_pattern(s : S) -> Unit {
  match s {
    { value } => println("Value is: \{value}")
  }
}
