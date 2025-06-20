type UserId Int
type UserName String

fn main {
  let user_id : UserId = UserId(1)
  let user_name : UserName = UserName("Alice")
  println(user_id.inner())
  println(user_name.inner())
  // use some pattern matching to extract the values
  let UserId(id) = user_id 
  let UserName(name) = user_name
}
