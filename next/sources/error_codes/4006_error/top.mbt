pub fn use_helper() -> Int32 {
  letrec helper = fn(n : Int32) -> Int32 {
    n
  } and helper = fn(n : Int32) -> Int32 {
    n + 1
  }
  helper(0)
}
