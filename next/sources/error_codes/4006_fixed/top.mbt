pub fn use_helpers() -> Int32 {
  letrec helper1 = fn(n : Int32) -> Int32 {
    n
  } and helper2 = fn(n : Int32) -> Int32 {
    n + 1
  }
  helper1(helper2(0))
}
