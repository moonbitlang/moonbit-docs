pub(all) struct S {
  a : Int
  b : Int
}

pub let s : S = { a: 1 }
//              ^~~~~~~~
// Error: Record fields b are undefined for type S
