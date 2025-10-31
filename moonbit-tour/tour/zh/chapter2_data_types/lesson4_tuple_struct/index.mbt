struct UserName(String)
struct Position(Int, Int)

fn main {
  let user : UserName = UserName("alice")
  let pos : Position = Position(1, 2)

  // 错误: (Int, Int) 和 Position 不是同一个类型
  // let pair : (Int, Int) = pos

  println(user.0)
  println(pos.0)
  println(pos.1)

  // 用模式匹配提取元组结构体内的值
  let UserName(name) = user
  let Position(x, y) = pos
}
