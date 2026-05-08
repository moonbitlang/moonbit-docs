///|
priv struct S {
  x : Int
}

///|
test {
  let s = { x: 1 }
  println(s.x)
  s.x = 2
}
