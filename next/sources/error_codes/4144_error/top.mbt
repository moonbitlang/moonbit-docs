pub const Value : Int32 = 1

pub fn classify(value : Int32) -> String {
  match value {
    Value(_) => "Value"
  //^~~~~
  // Error: 'Value' is a constant, not a constructor, it cannot be applied to arguments.
    _ => "Other"
  }
}
