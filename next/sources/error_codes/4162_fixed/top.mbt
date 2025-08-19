///|
#locals(f)
pub fn[A, B] fold(a : Array[A], init_~ : B, f : (B, A) -> B) -> B {
  let mut acc = init_
  for x in a {
    acc = f(acc, x)
  }
  acc
}
