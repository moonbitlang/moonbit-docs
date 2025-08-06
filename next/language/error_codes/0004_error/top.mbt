///|
struct Code(Int)

///|
fn Code::new(code : Int) -> Code {
  Code(code)
}

///|
test {
  let Code(_) = Code::new(42)

}
