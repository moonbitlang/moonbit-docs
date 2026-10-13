///|
struct A(Array[Int32])

///|
#alias("_[_]")
fn A::get(self : A, idx : Int32) -> Int32 {
  return self.0[idx]
}
