///|
pub(open) trait Ider {
  id(Self) -> Self
}

///|
impl Ider for Int with id(self) {
  concrete_id(self)
}

///|
pub fn trait_id(x : Int) -> Int {
  Ider::id(x)
}
