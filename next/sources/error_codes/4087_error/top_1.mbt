///|
priv struct S {
  x : Int32
}

///|
test {
  let s = { x: 1 }
  println(s.x)
  s.x = 2
}
