///|
#locals(f)
pub fn[A] map_inline(arr : ArrayView[A], f : (A) -> A) -> Unit {
  match arr {
    [hd, .. tl] => {
      arr[0] = f(hd)
      map_inline(tl, f) // The parameter is not local: it escapes.
    }
    [] => ()
  }
}
