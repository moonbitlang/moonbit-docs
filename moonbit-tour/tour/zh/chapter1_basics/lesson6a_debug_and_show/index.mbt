///|
fn main {
  let name : String = "MoonBit"
  let emails = [
    "moonbit@example.email",
    "moonbit-community@example.email",
    "moonbit-x@example.email",
  ]

  // 插值适合有显示格式的值。
  println("name: \{name}")

  // 想查看数据结构时，使用 to_repr。
  println("emails: \{to_repr(emails)}")

  // debug(x) 是 println("\{to_repr(x)}") 的简写。
  debug(emails)
}
