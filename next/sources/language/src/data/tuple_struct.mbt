// simple definition
struct UserId(Int)

struct UserInfo(UserId, String)
// end simple definition

test "tuple struct 2" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // create and destructure tuple struct
  let id : UserId = UserId(1)
  let name : UserInfo = UserInfo(id, "John Doe")
  let UserId(uid) = id // uid : Int
  let UserInfo(_, uname) = name // uname: String
  println(uid)
  println(uname)
  // end create and destructure tuple struct
  t.snapshot(filename="tuple_struct_2")
}

test "tuple struct 3" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // access tuple struct by index
  let id : UserId = UserId(1)
  let info : UserInfo = UserInfo(id, "John Doe")
  let uid : Int = id.0
  let uname : String = info.1
  println(uid)
  println(uname)
  // end access tuple struct by index
  t.snapshot(filename="tuple_struct_3")
}