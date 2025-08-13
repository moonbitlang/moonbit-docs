struct S {
  a : Int
  b : Int
  c : Int
}

fn main {
  let s : S = { a : 1, b : 2, c : 3 }
  let { a, .., c } = s
  //       ^^
  // Error: Unexpected `..` here, add `, ..` behind the last field to ignore the rest of struct.
}