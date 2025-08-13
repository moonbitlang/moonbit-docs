struct S {
  a : Int
  b : Int
}

fn main {
  let s : S = { a : 1, b : 2 }
  let ss = { ..s, a : 1 }
  ignore(ss)
}