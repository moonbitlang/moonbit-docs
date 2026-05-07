pub(all) struct S {
  a : Int
  b : Int
  c : Int
}

fn sum_selected(s : S) -> Int {
  let { a, .., c } = s
  a + c
}

test {
  inspect(sum_selected({ a: 1, b: 2, c: 3 }), content="4")
}
