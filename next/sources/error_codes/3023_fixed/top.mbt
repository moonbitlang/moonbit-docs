///|
pub trait Named {
  name(Self) -> String
}

///|
pub impl Named for Int with name(_self) { "user" }
