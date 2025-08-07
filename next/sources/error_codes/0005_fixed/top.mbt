// remove unused

///|
priv struct Foo {
  bar : Int
}
// end remove unused

// use underscore

///|
priv struct Foo2[_] {
  bar2 : Int
}
// end use underscore

///|
test {
  inspect({ bar: 42 }.bar, content="42")
  inspect(({ bar2: 42 } : Foo2[Int]).bar2, content="42")
}
