///|
#locals(f)
pub fn[A] map_inline(arr : ArrayView[A], f : (A) -> A) -> Unit {
  for i = 0; i < arr.length(); i = i + 1 {
    arr[i] = f(arr[i])
  }
}
