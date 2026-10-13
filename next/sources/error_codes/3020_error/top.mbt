pub(all) struct S {
  a : Int32
  b : Int32
}

fn replace_a(s : S) -> S {
  let ss = { ..s, a = 1 } // Error: Unexpected `=` in struct expression.
  ss
}

test {
  ignore(replace_a({ a: 0, b: 2 }))
}
