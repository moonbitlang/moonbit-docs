pub fn f(x: Int, y: Int) -> Int {
  loop x, y {
    0, 0 => 0
    a => continue a - 1, 0
//  ^ Error: This loop has 2 arguments, but 1 patterns are supplied
  }
}