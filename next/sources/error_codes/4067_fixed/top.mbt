///|
priv struct A(Int)

///|
fn A::to_int(self : A) -> Int {
  self.0
}

///|
fn main {
  let a = A(42)
  println(a.to_int())
}
