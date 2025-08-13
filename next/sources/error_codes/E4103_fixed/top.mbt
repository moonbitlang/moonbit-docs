pub fn f(x: Int, y: Int) -> Int {
  loop x, y {
    0, 0 => 0
    a, b => continue a - 1, b - 1
  }
}