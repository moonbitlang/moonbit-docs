struct Inner {
  value : Int
}

type! ErrorOuter Inner

enum EnumOuter {
  Outer(Inner)
}

fn main {
  let outer : ErrorOuter = ErrorOuter(Inner::{ value: 1 })
  println(outer.value) // Error: This expression has type ErrorOuter, which is an error type type and not a struct.
  let outer : EnumOuter = Outer(Inner::{ value: 2 })
  println(outer.value) // Error: This expression has type EnumOuter, which is a variant type and not a struct.
}