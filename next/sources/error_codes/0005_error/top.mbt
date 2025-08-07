///|
priv struct Foo[T] {
  bar : Int
}

///|
test {
  let bar : Foo[Int] = { bar: 42 }
  inspect(bar.bar, content="42")
}
