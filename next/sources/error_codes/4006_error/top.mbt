pub fn use_helper() -> Int {
  letrec helper = fn(n : Int) -> Int {
    n
  } and helper = fn(n : Int) -> Int {
    n + 1
  }
  helper(0)
}
