///|
pub trait Named {
  name(Self) -> String
}

///|
pub impl Named for Int32 with name(_self) { "user" }
