///|
pub trait Named {
  name(Self) -> String
}

///|
pub impl Named for Int {
  name(_self) { "user" }
}
