type UserId Int
type UserName String

fn main {
  let user_id : UserId = UserId(1)
  let user_name : UserName = UserName("Alice")
  let UserId(id) = user_id
  let UserName(name) = user_name
  println(user_id._)
  println(user_name._)
}
