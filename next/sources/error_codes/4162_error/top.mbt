///|
#locals(init_)
pub fn[A, B] fold(a : Array[A], init_~ : B, f : (B, A) -> B) -> B {
  //                            ^
  // This parameter is expected to be a function, but it is not.
  let mut acc = init_
  for x in a {
    acc = f(acc, x)
  }
  acc
}
