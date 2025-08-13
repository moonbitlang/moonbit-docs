///|
trait Ider {
  id(Self) -> Self
}

///|
impl Ider for Int with id(self) { int_id(self) }