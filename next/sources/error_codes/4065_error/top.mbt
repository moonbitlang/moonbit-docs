///|
struct A(Array[Int])

///|
#alias("_[_]")
fn A::get(self : A, idx : Int, offset? : Int) -> Int {
  //  ^~~~~~
  // Error: overloaded indexing should accept 2 arguments, but it accepts 3 arguments
  let idx = match offset {
    None => idx
    Some(offset) => idx + offset
  }
  return self.0[idx]
}
