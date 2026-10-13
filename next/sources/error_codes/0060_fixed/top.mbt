priv struct User {
  id : Int32
  name : String
  email : String
}

test {
  let user : User = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated = { ..user, email: "john@doe.name" }
  ignore(updated)
}
