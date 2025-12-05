///|
pub fn add1(x : Int) -> Int {
  @moonbitlang/core/builtin.Add::add(0, @c.incr(@pkgA.incr(x)))
}
