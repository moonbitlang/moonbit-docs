///|
pub fn add1(x : Int32) -> Int32 {
  @moonbitlang/core/builtin.Add::add(0, @c.incr(@pkgA.incr(x)))
}
