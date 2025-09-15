///|
#locals(f)
pub fn[A, B] map(
  arr : ArrayView[A],
  f : (A) -> B,
  target? : Array[B] = [],
) -> Array[B] {
  loop arr {
    [hd, .. tl] => {
      target.push(f(hd))
      continue tl
    }
    [] => target
  }
}
