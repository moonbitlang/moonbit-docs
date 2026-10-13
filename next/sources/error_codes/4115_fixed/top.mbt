///|
pub fn f(parameter? : Int32 = 0) -> Int32 {
  parameter
}

///|
test {
  inspect(f(), content="0")
  inspect(f(parameter=1), content="1")
}
