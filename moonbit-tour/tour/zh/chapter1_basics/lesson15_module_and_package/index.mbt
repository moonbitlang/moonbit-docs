///|
fn main {
  // 使用完整路径
  println(@moonbitlang/core/math.pow(2, 3))
  println(@moonbitlang/core/int.max_value)

  // 使用更短的别名
  println(@math.pow(2, 3))
  println(@int.max_value)
}
