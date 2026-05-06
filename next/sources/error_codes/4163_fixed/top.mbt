///|
#locals(f)
pub fn[A, B] map(
  arr : ArrayView[A],
  f : (A) -> B,
  target? : Array[B] = [],
) -> Array[B] {
  for item in arr {
    target.push(f(item))
  }
  target
}
