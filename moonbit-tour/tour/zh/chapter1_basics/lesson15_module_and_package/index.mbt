///|
fn main {
  // 使用完整路径
  println(@moonbitlang/core/math.pow(2, 3))
  println(@moonbitlang/core/int.MAX_VALUE)

  // 使用更短的别名
  println(@math.pow(2, 3))
  println(@int.MAX_VALUE)
}
