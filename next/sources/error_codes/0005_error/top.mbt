///|
priv struct Foo[T] {
  bar : Int32
}

///|
test {
  let bar : Foo[Int32] = { bar: 42 }
  inspect(bar.bar, content="42")
}
