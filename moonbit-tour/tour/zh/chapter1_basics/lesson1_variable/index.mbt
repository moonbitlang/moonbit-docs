///|
fn main {
  // 显式类型注解
  let a1 : Int = 10
  println((10 : Int))

  // 使用类型推断的变量（从值 20 推断出 Int 类型）
  let b = 20
  println("a1 + b = \{a1 + b}")

  // 可变变量 - 可以被修改
  let mut c = 10
  println("c 修改前: \{c}")
  c = c + 1
  println("c 修改后: \{c}")

  // 不可变变量 - 不能被修改
  let d = 20
  println("d = \{d}")
  // d = d + 1  // 取消注释这行会导致编译错误
}
