///|
priv struct A(Int32)

///|
fn A::to_int(self : A) -> Int32 {
  self.0
}

///|
fn main {
  let a = A(42)
  println(a.to_int())
}
