///|
struct A(Array[Int])

///|
fn A::op_get(self : A, idx : Int) -> Int {
  return self.0[idx]
}
