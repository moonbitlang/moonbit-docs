// remove unused

///|
priv struct Foo {
  bar : Int32
}
// end remove unused

// use underscore

///|
priv struct Foo2[_] {
  bar2 : Int32
}
// end use underscore

///|
test {
  inspect({ bar: 42 }.bar, content="42")
  inspect(({ bar2: 42 } : Foo2[Int32]).bar2, content="42")
}
