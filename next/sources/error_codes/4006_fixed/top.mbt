pub fn use_helpers() -> Int {
  letrec helper1 = fn(n : Int) -> Int {
    n
  } and helper2 = fn(n : Int) -> Int {
    n + 1
  }
  helper1(helper2(0))
}
