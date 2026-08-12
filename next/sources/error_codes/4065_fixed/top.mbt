///|
struct A(Array[Int])

///|
#alias("_[_]")
fn A::get(self : A, idx : Int) -> Int {
  return self.0[idx]
}
