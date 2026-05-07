///|
fn rename(user : @lib.User) -> @lib.User {
  { ..user, name: "new" }
}

///|
test {
  ignore(rename(@lib.default_user))
}
