///|
pub(all) struct S {
  a : Int32
  b : Int32
  c : Int32
}

///|
fn sum_selected(s : S) -> Int32 {
  let { a, c, .. } = s
  a + c
}

///|
test {
  inspect(sum_selected({ a: 1, b: 2, c: 3 }), content="4")
}
