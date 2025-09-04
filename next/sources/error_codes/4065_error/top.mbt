///|
struct A(Array[Int])

///|
fn A::op_get(self : A, idx : Int, offset? : Int) -> Int {
  //  ^~~~~~
  // Error: overloaded operator "op_get" should accept 2 arguments, but it accepts 3 arguments
  let idx = match offset {
    None => idx
    Some(offset) => idx + offset
  }
  return self.0[idx]
}
