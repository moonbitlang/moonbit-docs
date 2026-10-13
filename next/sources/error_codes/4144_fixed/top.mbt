pub const Value : Int32 = 1

pub fn classify(value : Int32) -> String {
  match value {
    Value => "Value"
    _ => "Other"
  }
}
