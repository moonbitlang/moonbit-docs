///|
fn main {
  // 整数的不同表示方式
  let dec : Int = 1000000 // 十进制
  let dec2 : Int = 1_000_000 // 十进制（使用下划线分隔符）
  let hex : Int = 0xFFFF // 十六进制（65535）
  let oct = 0o777 // 八进制（511）
  let bin = 0b1001 // 二进制（9）
  println("numbers:")
  println(dec) 
  println(dec2) 
  println(hex) 
  println(oct) 
  println(bin) 

  // 基本算术运算
  println("arithmetic:")
  println(1 + 2) // 加法: 3
  println(1 - 2) // 减法: -1
  println(1 * 2) // 乘法: 2
  println(5 / 2) // 除法: 2 (整数除法)
  println(10 % 3) // 取余: 1

  // 浮点数类型
  let num1 : Double = 3.14 // 双精度浮点数
  let num2 : Float = 3.14 // 单精度浮点数
  println("floating points:")
  println(num1) // 输出: 3.14
  println(num2) // 输出: 3.14
}
