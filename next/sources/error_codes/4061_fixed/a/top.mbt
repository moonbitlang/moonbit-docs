///|
pub(all) struct A(Int)

///|
pub(open) trait B {
  to_int(Self) -> Int
}
