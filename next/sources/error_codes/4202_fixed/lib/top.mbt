///|
pub(all) struct User {
  name : String
  priv id : Int
}

///|
pub let default_user : User = { name: "old", id: 1 }

///|
pub fn rename(user : User) -> User {
  { name: "new", id: user.id }
}
