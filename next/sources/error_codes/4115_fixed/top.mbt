///|
pub fn f(parameter? : Int = 0) -> Int {
  parameter
}

///|
test {
  inspect(f(), content="0")
  inspect(f(parameter=1), content="1")
}
