pub const Value : Int = 1

pub fn classify(value : Int) -> String {
  match value {
    Value(_) => "Value"
  //^~~~~
  // Error: 'Value' is a constant, not a constructor, it cannot be applied to arguments.
    _ => "Other"
  }
}
