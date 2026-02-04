priv struct User {
  id : Int
  name : String
  email : String
}

test {
  let user : User = { id: 0, name: "John Doe", email: "john@doe.com" }
  let _ = { ..user, id: 1, name: "Jane", email: "jane@doe.com" }
}
