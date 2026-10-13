///|
struct Code(Int32)

///|
fn Code::new(code : Int32) -> Code {
  Code(code)
}

///|
test {
  let Code(_) = Code::new(42)

}
