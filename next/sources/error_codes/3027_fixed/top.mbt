///|
pub fn require(condition : Bool) -> Bool {
  guard condition else { false }
  true
}
