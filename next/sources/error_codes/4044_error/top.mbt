pub(all) struct S {
  a : Int32
  b : Int32
}

pub let s : S = { a: 1 }
//              ^~~~~~~~
// Error: Record fields b are undefined for type S
