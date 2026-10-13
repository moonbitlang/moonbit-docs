// make private

///|
priv struct Code(Int32)

// end make private

///|
fn Code::new(value : Int32) -> Code {
  return value
}

///|
test {
  inspect(Code::new(1).0, content="1")
}

// make public

///|
struct Code2(Int32)

///|
pub fn Code2::new(value : Int32) -> Code2 {
  return value
}
// end make public

///|
test {
  inspect(Code2::new(1).0, content="1")
}
