///|
pub trait Named {
  name(Self) -> String
}

///|
pub impl Named for Int32 {
  name(_self) { "user" }
}
