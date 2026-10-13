///|
struct A(Array[Int32])

///|
#alias("_[_]")
fn A::get(self : A, idx : Int32, offset? : Int32) -> Int32 {
  //  ^~~~~~
  // Error: overloaded indexing should accept 2 arguments, but it accepts 3 arguments
  let idx = match offset {
    None => idx
    Some(offset) => idx + offset
  }
  return self.0[idx]
}
