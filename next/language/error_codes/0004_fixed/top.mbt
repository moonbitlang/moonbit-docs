// make private

///|
priv struct Code(Int)

// end make private

///|
fn Code::new(value : Int) -> Code {
  return value
}

///|
test {
  inspect(Code::new(1).0, content="1")
}

// make public

///|
struct Code2(Int) derive(Show)

///|
pub fn Code2::new(value : Int) -> Code2 {
  return value
}
// end make public

///|
test {
  inspect(Code2::new(1), content="Code2(1)")
}
