///|
#locals(f)
pub fn[A, B] map(
  arr : ArrayView[A],
  f : (A) -> B,
  target? : Array[B] = [],
) -> Array[B] {
  match arr {
    [hd, .. tl] => {
      target.push(f(hd))
      map(tl, f, target~) // The parameter is not local: it escapes.
    }
    [] => target
  }
}
