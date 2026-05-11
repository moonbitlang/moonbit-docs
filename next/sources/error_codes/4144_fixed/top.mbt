pub const Value : Int = 1

pub fn classify(value : Int) -> String {
  match value {
    Value => "Value"
    _ => "Other"
  }
}
