struct UserName(String)
struct Position(Int, Int)

fn main {
  let user : UserName = UserName("alice")
  let pos : Position = Position(1, 2)

  // error: (Int, Int) and Position are not the same type
  // let pair : (Int, Int) = pos

  println(user.0)
  println(pos.0)
  println(pos.1)

  // use some pattern matching to extract the values
  let UserName(name) = user
  let Position(x, y) = pos
}
